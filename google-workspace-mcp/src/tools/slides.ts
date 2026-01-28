import { z } from "zod";
import { getGoogleServices } from "../auth/oauth.js";

/**
 * Slides 도구 정의
 */
export const slidesTools = {
  slides_create: {
    description: "새 Google Slides 프레젠테이션을 생성합니다",
    schema: {
      title: z.string().describe("프레젠테이션 제목"),
      folderId: z.string().optional().describe("저장할 폴더 ID"),
    },
    handler: async ({ title, folderId }: { title: string; folderId?: string }) => {
      const { slides, drive } = await getGoogleServices();

      const response = await slides.presentations.create({
        requestBody: { title },
      });

      const presentationId = response.data.presentationId!;

      // 폴더로 이동
      if (folderId) {
        const file = await drive.files.get({
          fileId: presentationId,
          fields: "parents",
        });
        await drive.files.update({
          fileId: presentationId,
          addParents: folderId,
          removeParents: file.data.parents?.join(","),
        });
      }

      const file = await drive.files.get({
        fileId: presentationId,
        fields: "webViewLink",
      });

      return {
        success: true,
        presentationId,
        title,
        link: file.data.webViewLink,
        slideCount: response.data.slides?.length || 0,
        message: `프레젠테이션 "${title}"이 생성되었습니다.`,
      };
    },
  },

  slides_get_info: {
    description: "프레젠테이션 정보를 조회합니다",
    schema: {
      presentationId: z.string().describe("프레젠테이션 ID"),
    },
    handler: async ({ presentationId }: { presentationId: string }) => {
      const { slides } = await getGoogleServices();

      const response = await slides.presentations.get({
        presentationId,
      });

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
    description: "프레젠테이션의 슬라이드 내용을 읽습니다",
    schema: {
      presentationId: z.string().describe("프레젠테이션 ID"),
    },
    handler: async ({ presentationId }: { presentationId: string }) => {
      const { slides } = await getGoogleServices();

      const response = await slides.presentations.get({
        presentationId,
      });

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
    description: "프레젠테이션에 새 슬라이드를 추가합니다",
    schema: {
      presentationId: z.string().describe("프레젠테이션 ID"),
      title: z.string().optional().describe("슬라이드 제목"),
      body: z.string().optional().describe("슬라이드 본문"),
      layout: z.enum(["BLANK", "TITLE", "TITLE_AND_BODY", "TITLE_ONLY", "ONE_COLUMN_TEXT", "MAIN_POINT"])
        .optional().default("TITLE_AND_BODY").describe("레이아웃"),
    },
    handler: async ({ presentationId, title, body, layout }: {
      presentationId: string;
      title?: string;
      body?: string;
      layout: string;
    }) => {
      const { slides } = await getGoogleServices();

      const slideId = `slide_${Date.now()}`;

      const requests: any[] = [
        {
          createSlide: {
            objectId: slideId,
            slideLayoutReference: {
              predefinedLayout: layout,
            },
          },
        },
      ];

      await slides.presentations.batchUpdate({
        presentationId,
        requestBody: { requests },
      });

      // 제목과 본문 추가
      if (title || body) {
        const presentation = await slides.presentations.get({ presentationId });
        const newSlide = presentation.data.slides?.find((s) => s.objectId === slideId);

        const textRequests: any[] = [];

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
          await slides.presentations.batchUpdate({
            presentationId,
            requestBody: { requests: textRequests },
          });
        }
      }

      return {
        success: true,
        slideId,
        message: "새 슬라이드가 추가되었습니다.",
      };
    },
  },

  slides_delete_slide: {
    description: "슬라이드를 삭제합니다",
    schema: {
      presentationId: z.string().describe("프레젠테이션 ID"),
      slideId: z.string().describe("슬라이드 ID"),
    },
    handler: async ({ presentationId, slideId }: { presentationId: string; slideId: string }) => {
      const { slides } = await getGoogleServices();

      await slides.presentations.batchUpdate({
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
      });

      return {
        success: true,
        message: "슬라이드가 삭제되었습니다.",
      };
    },
  },

  slides_duplicate_slide: {
    description: "슬라이드를 복제합니다",
    schema: {
      presentationId: z.string().describe("프레젠테이션 ID"),
      slideId: z.string().describe("복제할 슬라이드 ID"),
    },
    handler: async ({ presentationId, slideId }: { presentationId: string; slideId: string }) => {
      const { slides } = await getGoogleServices();

      const newSlideId = `slide_copy_${Date.now()}`;

      await slides.presentations.batchUpdate({
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
      });

      return {
        success: true,
        newSlideId,
        message: "슬라이드가 복제되었습니다.",
      };
    },
  },

  slides_move_slide: {
    description: "슬라이드 순서를 변경합니다",
    schema: {
      presentationId: z.string().describe("프레젠테이션 ID"),
      slideId: z.string().describe("이동할 슬라이드 ID"),
      insertionIndex: z.number().describe("새 위치 (0부터 시작)"),
    },
    handler: async ({ presentationId, slideId, insertionIndex }: {
      presentationId: string;
      slideId: string;
      insertionIndex: number;
    }) => {
      const { slides } = await getGoogleServices();

      await slides.presentations.batchUpdate({
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
      });

      return {
        success: true,
        message: `슬라이드가 ${insertionIndex + 1}번 위치로 이동되었습니다.`,
      };
    },
  },

  slides_add_text: {
    description: "슬라이드에 텍스트 박스를 추가합니다",
    schema: {
      presentationId: z.string().describe("프레젠테이션 ID"),
      slideId: z.string().describe("슬라이드 ID"),
      text: z.string().describe("텍스트 내용"),
      x: z.number().optional().default(100).describe("X 위치 (pt)"),
      y: z.number().optional().default(100).describe("Y 위치 (pt)"),
      width: z.number().optional().default(300).describe("너비 (pt)"),
      height: z.number().optional().default(50).describe("높이 (pt)"),
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

      await slides.presentations.batchUpdate({
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
      });

      return {
        success: true,
        textBoxId,
        message: "텍스트 박스가 추가되었습니다.",
      };
    },
  },

  slides_replace_text: {
    description: "프레젠테이션 전체에서 텍스트를 찾아 바꿉니다",
    schema: {
      presentationId: z.string().describe("프레젠테이션 ID"),
      searchText: z.string().describe("찾을 텍스트"),
      replaceText: z.string().describe("바꿀 텍스트"),
      matchCase: z.boolean().optional().default(false).describe("대소문자 구분"),
    },
    handler: async ({ presentationId, searchText, replaceText, matchCase }: {
      presentationId: string;
      searchText: string;
      replaceText: string;
      matchCase: boolean;
    }) => {
      const { slides } = await getGoogleServices();

      const response = await slides.presentations.batchUpdate({
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
      });

      const occurrences = response.data.replies?.[0]?.replaceAllText?.occurrencesChanged || 0;

      return {
        success: true,
        occurrencesChanged: occurrences,
        message: `${occurrences}개의 텍스트가 변경되었습니다.`,
      };
    },
  },
};
