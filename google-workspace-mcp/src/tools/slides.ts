import { z } from "zod";
import { getGoogleServices } from "../auth/oauth.js";
import { withRetry } from "../utils/retry.js";
import { messages, msg } from "../utils/messages.js";

/**
 * Slides tool definitions
 */
export const slidesTools = {
  slides_create: {
    description: "Create a new Google Slides presentation",
    schema: {
      title: z.string().describe("Presentation title"),
      folderId: z.string().optional().describe("Destination folder ID"),
    },
    handler: async ({ title, folderId }: { title: string; folderId?: string }) => {
      const { slides, drive } = await getGoogleServices();

      const response = await withRetry(() =>
        slides.presentations.create({
          requestBody: { title },
        })
      );

      const presentationId = response.data.presentationId!;

      // Move to folder
      if (folderId) {
        const file = await withRetry(() =>
          drive.files.get({
            fileId: presentationId,
            fields: "parents",
          })
        );
        await withRetry(() =>
          drive.files.update({
            fileId: presentationId,
            addParents: folderId,
            removeParents: file.data.parents?.join(","),
          })
        );
      }

      const file = await withRetry(() =>
        drive.files.get({
          fileId: presentationId,
          fields: "webViewLink",
        })
      );

      return {
        success: true,
        presentationId,
        title,
        link: file.data.webViewLink,
        slideCount: response.data.slides?.length || 0,
        message: msg(messages.slides.presentationCreated, title),
      };
    },
  },

  slides_get_info: {
    description: "Get presentation information",
    schema: {
      presentationId: z.string().describe("Presentation ID"),
    },
    handler: async ({ presentationId }: { presentationId: string }) => {
      const { slides } = await getGoogleServices();

      const response = await withRetry(() =>
        slides.presentations.get({
          presentationId,
        })
      );

      return {
        presentationId,
        title: response.data.title,
        slideCount: response.data.slides?.length || 0,
        pageSize: response.data.pageSize,
        slides: response.data.slides?.map((slide, index) => ({
          slideIndex: index + 1,
          objectId: slide.objectId,
        })),
      };
    },
  },

  slides_read: {
    description: "Read slide content from a presentation",
    schema: {
      presentationId: z.string().describe("Presentation ID"),
    },
    handler: async ({ presentationId }: { presentationId: string }) => {
      const { slides } = await getGoogleServices();

      const response = await withRetry(() =>
        slides.presentations.get({
          presentationId,
        })
      );

      const slidesList = response.data.slides || [];

      return {
        presentationId,
        title: response.data.title,
        slideCount: slidesList.length,
        slides: slidesList.map((slide, index) => {
          let text = "";
          for (const element of slide.pageElements || []) {
            if (element.shape?.text?.textElements) {
              for (const textElem of element.shape.text.textElements) {
                if (textElem.textRun?.content) {
                  text += textElem.textRun.content;
                }
              }
            }
          }
          return {
            slideIndex: index + 1,
            slideId: slide.objectId,
            text: text.trim().slice(0, 1000),
          };
        }),
      };
    },
  },

  slides_add_slide: {
    description: "Add a new slide to the presentation",
    schema: {
      presentationId: z.string().describe("Presentation ID"),
      title: z.string().optional().describe("Slide title"),
      body: z.string().optional().describe("Slide body"),
      layout: z.enum(["BLANK", "TITLE", "TITLE_AND_BODY", "TITLE_ONLY", "ONE_COLUMN_TEXT", "MAIN_POINT"])
        .optional().default("TITLE_AND_BODY").describe("Layout type"),
    },
    handler: async ({ presentationId, title, body, layout }: {
      presentationId: string;
      title?: string;
      body?: string;
      layout: string;
    }) => {
      const { slides } = await getGoogleServices();

      const slideId = `slide_${Date.now()}`;

      // FR-S3-07: Typed requests instead of any
      const requests: Record<string, unknown>[] = [
        {
          createSlide: {
            objectId: slideId,
            slideLayoutReference: {
              predefinedLayout: layout,
            },
          },
        },
      ];

      await withRetry(() =>
        slides.presentations.batchUpdate({
          presentationId,
          requestBody: { requests },
        })
      );

      // Add title and body text
      if (title || body) {
        const presentation = await withRetry(() =>
          slides.presentations.get({ presentationId })
        );
        const newSlide = presentation.data.slides?.find((s) => s.objectId === slideId);

        const textRequests: Record<string, unknown>[] = [];

        if (newSlide?.pageElements) {
          for (const element of newSlide.pageElements) {
            const placeholder = element.shape?.placeholder;
            if (placeholder?.type === "TITLE" && title) {
              textRequests.push({
                insertText: {
                  objectId: element.objectId,
                  text: title,
                },
              });
            }
            if (placeholder?.type === "BODY" && body) {
              textRequests.push({
                insertText: {
                  objectId: element.objectId,
                  text: body,
                },
              });
            }
          }
        }

        if (textRequests.length > 0) {
          await withRetry(() =>
            slides.presentations.batchUpdate({
              presentationId,
              requestBody: { requests: textRequests },
            })
          );
        }
      }

      return {
        success: true,
        slideId,
        message: messages.slides.slideAdded,
      };
    },
  },

  slides_delete_slide: {
    description: "Delete a slide",
    schema: {
      presentationId: z.string().describe("Presentation ID"),
      slideId: z.string().describe("Slide ID"),
    },
    handler: async ({ presentationId, slideId }: { presentationId: string; slideId: string }) => {
      const { slides } = await getGoogleServices();

      await withRetry(() =>
        slides.presentations.batchUpdate({
          presentationId,
          requestBody: {
            requests: [
              {
                deleteObject: {
                  objectId: slideId,
                },
              },
            ],
          },
        })
      );

      return {
        success: true,
        message: messages.slides.slideDeleted,
      };
    },
  },

  slides_duplicate_slide: {
    description: "Duplicate a slide",
    schema: {
      presentationId: z.string().describe("Presentation ID"),
      slideId: z.string().describe("Slide ID to duplicate"),
    },
    handler: async ({ presentationId, slideId }: { presentationId: string; slideId: string }) => {
      const { slides } = await getGoogleServices();

      const newSlideId = `slide_copy_${Date.now()}`;

      await withRetry(() =>
        slides.presentations.batchUpdate({
          presentationId,
          requestBody: {
            requests: [
              {
                duplicateObject: {
                  objectId: slideId,
                  objectIds: {
                    [slideId]: newSlideId,
                  },
                },
              },
            ],
          },
        })
      );

      return {
        success: true,
        newSlideId,
        message: "Slide duplicated.",
      };
    },
  },

  slides_move_slide: {
    description: "Change slide position",
    schema: {
      presentationId: z.string().describe("Presentation ID"),
      slideId: z.string().describe("Slide ID to move"),
      insertionIndex: z.number().describe("New position (0-based)"),
    },
    handler: async ({ presentationId, slideId, insertionIndex }: {
      presentationId: string;
      slideId: string;
      insertionIndex: number;
    }) => {
      const { slides } = await getGoogleServices();

      await withRetry(() =>
        slides.presentations.batchUpdate({
          presentationId,
          requestBody: {
            requests: [
              {
                updateSlidesPosition: {
                  slideObjectIds: [slideId],
                  insertionIndex,
                },
              },
            ],
          },
        })
      );

      return {
        success: true,
        message: `Slide moved to position ${insertionIndex + 1}.`,
      };
    },
  },

  slides_add_text: {
    description: "Add a text box to a slide",
    schema: {
      presentationId: z.string().describe("Presentation ID"),
      slideId: z.string().describe("Slide ID"),
      text: z.string().describe("Text content"),
      x: z.number().optional().default(100).describe("X position (pt)"),
      y: z.number().optional().default(100).describe("Y position (pt)"),
      width: z.number().optional().default(300).describe("Width (pt)"),
      height: z.number().optional().default(50).describe("Height (pt)"),
    },
    handler: async ({ presentationId, slideId, text, x, y, width, height }: {
      presentationId: string;
      slideId: string;
      text: string;
      x: number;
      y: number;
      width: number;
      height: number;
    }) => {
      const { slides } = await getGoogleServices();

      const textBoxId = `textbox_${Date.now()}`;

      await withRetry(() =>
        slides.presentations.batchUpdate({
          presentationId,
          requestBody: {
            requests: [
              {
                createShape: {
                  objectId: textBoxId,
                  shapeType: "TEXT_BOX",
                  elementProperties: {
                    pageObjectId: slideId,
                    size: {
                      width: { magnitude: width, unit: "PT" },
                      height: { magnitude: height, unit: "PT" },
                    },
                    transform: {
                      scaleX: 1,
                      scaleY: 1,
                      translateX: x,
                      translateY: y,
                      unit: "PT",
                    },
                  },
                },
              },
              {
                insertText: {
                  objectId: textBoxId,
                  text,
                },
              },
            ],
          },
        })
      );

      return {
        success: true,
        textBoxId,
        message: messages.slides.textAdded,
      };
    },
  },

  slides_replace_text: {
    description: "Find and replace text across the entire presentation",
    schema: {
      presentationId: z.string().describe("Presentation ID"),
      searchText: z.string().describe("Text to find"),
      replaceText: z.string().describe("Replacement text"),
      matchCase: z.boolean().optional().default(false).describe("Case sensitive"),
    },
    handler: async ({ presentationId, searchText, replaceText, matchCase }: {
      presentationId: string;
      searchText: string;
      replaceText: string;
      matchCase: boolean;
    }) => {
      const { slides } = await getGoogleServices();

      const response = await withRetry(() =>
        slides.presentations.batchUpdate({
          presentationId,
          requestBody: {
            requests: [
              {
                replaceAllText: {
                  containsText: {
                    text: searchText,
                    matchCase,
                  },
                  replaceText,
                },
              },
            ],
          },
        })
      );

      const occurrences = response.data.replies?.[0]?.replaceAllText?.occurrencesChanged || 0;

      return {
        success: true,
        occurrencesChanged: occurrences,
        message: `${occurrences} text occurrences replaced.`,
      };
    },
  },
};
