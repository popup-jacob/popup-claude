import { describe, it, expect, vi, beforeEach } from 'vitest';
import { slidesTools } from '../slides.js';

// Mock getGoogleServices
const mockSlidesApi = {
  presentations: {
    create: vi.fn(),
    get: vi.fn(),
    batchUpdate: vi.fn(),
  },
};

const mockDriveApi = {
  files: {
    update: vi.fn(),
    get: vi.fn(),
  },
};

vi.mock('../../auth/oauth', () => ({
  getGoogleServices: vi.fn(async () => ({
    slides: mockSlidesApi,
    drive: mockDriveApi,
  })),
}));

describe('Slides Tools - Core Functionality', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('slides_create - TC-SL01: Presentation Creation', () => {
    it('should create a new presentation with title only', async () => {
      mockSlidesApi.presentations.create.mockResolvedValue({
        data: {
          presentationId: 'pres123',
          title: 'New Presentation',
        },
      });

      mockDriveApi.files.get.mockResolvedValue({
        data: {
          webViewLink: 'https://docs.google.com/presentation/d/pres123',
        },
      });

      const result = await slidesTools.slides_create.handler({
        title: 'New Presentation',
      });

      expect(result.success).toBe(true);
      expect(result.presentationId).toBe('pres123');
      expect(mockSlidesApi.presentations.create).toHaveBeenCalledWith({
        requestBody: {
          title: 'New Presentation',
        },
      });
    });

    it('should move presentation to folder if folderId is provided', async () => {
      mockSlidesApi.presentations.create.mockResolvedValue({
        data: {
          presentationId: 'pres456',
          title: 'Presentation in Folder',
        },
      });

      mockDriveApi.files.get.mockResolvedValue({
        data: {
          parents: ['oldFolder'],
          webViewLink: 'https://docs.google.com/presentation/d/pres456',
        },
      });

      mockDriveApi.files.update.mockResolvedValue({ data: {} });

      const result = await slidesTools.slides_create.handler({
        title: 'Presentation in Folder',
        folderId: 'folder123',
      });

      expect(result.success).toBe(true);
      expect(mockDriveApi.files.update).toHaveBeenCalledWith(
        expect.objectContaining({
          fileId: 'pres456',
          addParents: 'folder123',
        })
      );
    });
  });

  describe('slides_get_info - TC-SL02: Getting Presentation Info', () => {
    it('should return presentation metadata', async () => {
      mockSlidesApi.presentations.get.mockResolvedValue({
        data: {
          presentationId: 'pres123',
          title: 'My Presentation',
          slides: [
            {
              objectId: 'slide1',
              slideProperties: {},
            },
            {
              objectId: 'slide2',
              slideProperties: {},
            },
          ],
        },
      });

      const result = await slidesTools.slides_get_info.handler({
        presentationId: 'pres123',
      });

      expect(result.presentationId).toBe('pres123');
      expect(result.title).toBe('My Presentation');
      expect(result.slideCount).toBe(2);
    });

    it('should handle presentation with no slides', async () => {
      mockSlidesApi.presentations.get.mockResolvedValue({
        data: {
          presentationId: 'pres_empty',
          title: 'Empty Presentation',
          slides: [],
        },
      });

      const result = await slidesTools.slides_get_info.handler({
        presentationId: 'pres_empty',
      });

      expect(result.slideCount).toBe(0);
    });
  });

  describe('slides_add_slide - TC-SL03: Adding Slides', () => {
    it('should add a new slide with default layout', async () => {
      mockSlidesApi.presentations.batchUpdate.mockResolvedValue({
        data: {
          replies: [
            {
              createSlide: {
                objectId: 'slide_new',
              },
            },
          ],
        },
      });

      const result = await slidesTools.slides_add_slide.handler({
        presentationId: 'pres123',
        layout: 'TITLE_AND_BODY',
      });

      expect(result.success).toBe(true);
      expect(mockSlidesApi.presentations.batchUpdate).toHaveBeenCalledWith({
        presentationId: 'pres123',
        requestBody: {
          requests: [
            {
              createSlide: expect.objectContaining({
                slideLayoutReference: {
                  predefinedLayout: 'TITLE_AND_BODY',
                },
              }),
            },
          ],
        },
      });
    });

    it('should add slide with title and body', async () => {
      mockSlidesApi.presentations.batchUpdate.mockResolvedValue({
        data: {
          replies: [
            {
              createSlide: {
                objectId: 'slide_with_content',
              },
            },
          ],
        },
      });

      mockSlidesApi.presentations.get.mockResolvedValue({
        data: {
          slides: [
            {
              objectId: 'slide_with_content',
              pageElements: [
                {
                  objectId: 'title_elem',
                  shape: {
                    placeholder: {
                      type: 'TITLE',
                    },
                  },
                },
                {
                  objectId: 'body_elem',
                  shape: {
                    placeholder: {
                      type: 'BODY',
                    },
                  },
                },
              ],
            },
          ],
        },
      });

      const result = await slidesTools.slides_add_slide.handler({
        presentationId: 'pres123',
        title: 'Slide Title',
        body: 'Slide body content',
        layout: 'TITLE_AND_BODY',
      });

      expect(result.success).toBe(true);
      expect(mockSlidesApi.presentations.batchUpdate).toHaveBeenCalled();
      expect(mockSlidesApi.presentations.get).toHaveBeenCalled();
    });
  });

  describe('slides_add_text - TC-SL04: Adding Text to Slides', () => {
    it('should add text box to a slide with default dimensions', async () => {
      mockSlidesApi.presentations.batchUpdate.mockResolvedValue({
        data: {
          replies: [
            {
              createShape: {
                objectId: 'textbox123',
              },
            },
          ],
        },
      });

      const result = await slidesTools.slides_add_text.handler({
        presentationId: 'pres123',
        slideId: 'slide1',
        text: 'Hello World',
        x: 100,
        y: 100,
        width: 300,
        height: 50,
      });

      expect(result.success).toBe(true);
      expect(mockSlidesApi.presentations.batchUpdate).toHaveBeenCalled();
    });
  });

  describe('slides_delete_slide - TC-SL05: Deleting Slides', () => {
    it('should delete a slide by objectId', async () => {
      mockSlidesApi.presentations.batchUpdate.mockResolvedValue({
        data: {},
      });

      const result = await slidesTools.slides_delete_slide.handler({
        presentationId: 'pres123',
        slideId: 'slide2',
      });

      expect(result.success).toBe(true);
      expect(mockSlidesApi.presentations.batchUpdate).toHaveBeenCalledWith({
        presentationId: 'pres123',
        requestBody: {
          requests: [
            {
              deleteObject: {
                objectId: 'slide2',
              },
            },
          ],
        },
      });
    });
  });

  describe('slides_read - TC-SL06: Reading Slide Content', () => {
    it('should extract text from slides', async () => {
      mockSlidesApi.presentations.get.mockResolvedValue({
        data: {
          presentationId: 'pres123',
          title: 'Test Presentation',
          slides: [
            {
              objectId: 'slide1',
              pageElements: [
                {
                  shape: {
                    text: {
                      textElements: [
                        {
                          textRun: {
                            content: 'Title Text\n',
                          },
                        },
                      ],
                    },
                  },
                },
              ],
            },
            {
              objectId: 'slide2',
              pageElements: [
                {
                  shape: {
                    text: {
                      textElements: [
                        {
                          textRun: {
                            content: 'Body Text\n',
                          },
                        },
                      ],
                    },
                  },
                },
              ],
            },
          ],
        },
      });

      const result = await slidesTools.slides_read.handler({
        presentationId: 'pres123',
      });

      expect(result.presentationId).toBe('pres123');
      expect(result.title).toBe('Test Presentation');
      expect(result.slides).toHaveLength(2);
      expect(result.slides![0].text).toContain('Title Text');
      expect(result.slides![1].text).toContain('Body Text');
    });

    it('should handle slides with no text elements', async () => {
      mockSlidesApi.presentations.get.mockResolvedValue({
        data: {
          presentationId: 'pres_no_text',
          title: 'Image Only Presentation',
          slides: [
            {
              objectId: 'slide_img',
              pageElements: [
                {
                  image: {
                    contentUrl: 'https://example.com/image.png',
                  },
                },
              ],
            },
          ],
        },
      });

      const result = await slidesTools.slides_read.handler({
        presentationId: 'pres_no_text',
      });

      expect(result.slides).toHaveLength(1);
      expect(result.slides![0].text).toBe('');
    });
  });

  describe('slides_duplicate_slide - TC-SL07: Duplicating Slides', () => {
    it('should duplicate a slide', async () => {
      mockSlidesApi.presentations.batchUpdate.mockResolvedValue({
        data: {
          replies: [
            {
              duplicateObject: {
                objectId: 'slide_duplicate',
              },
            },
          ],
        },
      });

      const result = await slidesTools.slides_duplicate_slide.handler({
        presentationId: 'pres123',
        slideId: 'slide1',
      });

      expect(result.success).toBe(true);
      expect(mockSlidesApi.presentations.batchUpdate).toHaveBeenCalledWith(
        expect.objectContaining({
          presentationId: 'pres123',
          requestBody: expect.objectContaining({
            requests: expect.arrayContaining([
              expect.objectContaining({
                duplicateObject: expect.objectContaining({
                  objectId: 'slide1',
                }),
              }),
            ]),
          }),
        })
      );
    });
  });
});
