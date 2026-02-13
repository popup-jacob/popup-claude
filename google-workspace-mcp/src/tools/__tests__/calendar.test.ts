import { describe, it, expect, vi, beforeEach } from 'vitest';
import { calendarTools } from '../calendar.js';

// Mock getGoogleServices
const mockCalendarApi = {
  calendarList: {
    list: vi.fn(),
  },
  events: {
    list: vi.fn(),
    get: vi.fn(),
    insert: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
    quickAdd: vi.fn(),
    patch: vi.fn(),
  },
  freebusy: {
    query: vi.fn(),
  },
};

vi.mock('../../auth/oauth', () => ({
  getGoogleServices: vi.fn(async () => ({
    calendar: mockCalendarApi,
  })),
}));

// Mock time utilities
vi.mock('../../utils/time', () => ({
  getTimezone: vi.fn(() => 'Asia/Seoul'),
  parseTime: vi.fn((input: string) => {
    // Simple passthrough for ISO strings, or convert simple format
    if (input.includes('T')) return input;
    return new Date(input.replace(' ', 'T') + ':00+09:00').toISOString();
  }),
}));

describe('Calendar Tools - Core Functionality (P1)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('calendar_list_calendars - TC-C01: Calendar Listing', () => {
    it('should return formatted calendar list', async () => {
      mockCalendarApi.calendarList.list.mockResolvedValue({
        data: {
          items: [
            {
              id: 'primary',
              summary: 'My Calendar',
              description: 'Personal calendar',
              primary: true,
              accessRole: 'owner',
              backgroundColor: '#4285f4',
            },
            {
              id: 'team@group.calendar.google.com',
              summary: 'Team Calendar',
              primary: false,
              accessRole: 'writer',
              backgroundColor: '#0b8043',
            },
          ],
        },
      });

      const result = await calendarTools.calendar_list_calendars.handler();

      expect(result.calendars).toHaveLength(2);
      expect(result.calendars[0]).toEqual({
        id: 'primary',
        name: 'My Calendar',
        description: 'Personal calendar',
        primary: true,
        accessRole: 'owner',
        backgroundColor: '#4285f4',
      });
    });

    it('should handle empty calendar list', async () => {
      mockCalendarApi.calendarList.list.mockResolvedValue({
        data: { items: [] },
      });

      const result = await calendarTools.calendar_list_calendars.handler();

      expect(result.calendars).toHaveLength(0);
    });
  });

  describe('calendar_list_events - TC-C02: Event Listing', () => {
    it('should return formatted events with attendees', async () => {
      mockCalendarApi.events.list.mockResolvedValue({
        data: {
          items: [
            {
              id: 'event1',
              summary: 'Team Meeting',
              description: 'Weekly standup',
              start: { dateTime: '2026-02-13T10:00:00+09:00' },
              end: { dateTime: '2026-02-13T11:00:00+09:00' },
              location: 'Meeting Room A',
              attendees: [
                { email: 'alice@example.com', displayName: 'Alice', responseStatus: 'accepted' },
                { email: 'bob@example.com', displayName: 'Bob', responseStatus: 'tentative' },
              ],
              htmlLink: 'https://calendar.google.com/event?id=event1',
              status: 'confirmed',
              creator: { email: 'alice@example.com' },
              organizer: { email: 'alice@example.com' },
            },
          ],
        },
      });

      const result = await calendarTools.calendar_list_events.handler({
        calendarId: 'primary',
        maxResults: 10,
      });

      expect(result.total).toBe(1);
      expect(result.events[0].title).toBe('Team Meeting');
      expect(result.events[0].attendees).toHaveLength(2);
      expect(result.events[0].attendees![0].responseStatus).toBe('accepted');
    });

    it('should handle all-day events', async () => {
      mockCalendarApi.events.list.mockResolvedValue({
        data: {
          items: [
            {
              id: 'allday1',
              summary: 'Holiday',
              start: { date: '2026-02-14' },
              end: { date: '2026-02-15' },
              status: 'confirmed',
            },
          ],
        },
      });

      const result = await calendarTools.calendar_list_events.handler({
        calendarId: 'primary',
        maxResults: 10,
      });

      expect(result.events[0].start).toBe('2026-02-14');
      expect(result.events[0].end).toBe('2026-02-15');
    });

    it('should use default time range when not specified', async () => {
      mockCalendarApi.events.list.mockResolvedValue({
        data: { items: [] },
      });

      await calendarTools.calendar_list_events.handler({
        calendarId: 'primary',
        maxResults: 10,
      });

      const calledArgs = mockCalendarApi.events.list.mock.calls[0][0];
      expect(calledArgs.timeMin).toBeDefined();
      expect(calledArgs.timeMax).toBeDefined();
      expect(calledArgs.singleEvents).toBe(true);
      expect(calledArgs.orderBy).toBe('startTime');
    });
  });

  describe('calendar_create_event - TC-C03: Event Creation', () => {
    it('should create event with timezone', async () => {
      mockCalendarApi.events.insert.mockResolvedValue({
        data: {
          id: 'newEvent1',
          htmlLink: 'https://calendar.google.com/event?id=newEvent1',
        },
      });

      const result = await calendarTools.calendar_create_event.handler({
        title: 'New Meeting',
        startTime: '2026-02-14T14:00:00+09:00',
        endTime: '2026-02-14T15:00:00+09:00',
        calendarId: 'primary',
        sendNotifications: true,
      });

      expect(result.success).toBe(true);
      expect(result.eventId).toBe('newEvent1');

      const calledArgs = mockCalendarApi.events.insert.mock.calls[0][0];
      expect(calledArgs.requestBody.summary).toBe('New Meeting');
      expect(calledArgs.requestBody.start.timeZone).toBe('Asia/Seoul');
      expect(calledArgs.requestBody.end.timeZone).toBe('Asia/Seoul');
    });

    it('should include attendees and send notifications', async () => {
      mockCalendarApi.events.insert.mockResolvedValue({
        data: { id: 'newEvent2', htmlLink: 'https://calendar.google.com/event?id=newEvent2' },
      });

      const result = await calendarTools.calendar_create_event.handler({
        title: 'Team Sync',
        startTime: '2026-02-14T10:00:00+09:00',
        endTime: '2026-02-14T10:30:00+09:00',
        attendees: ['alice@example.com', 'bob@example.com'],
        calendarId: 'primary',
        sendNotifications: true,
      });

      const calledArgs = mockCalendarApi.events.insert.mock.calls[0][0];
      expect(calledArgs.requestBody.attendees).toEqual([
        { email: 'alice@example.com' },
        { email: 'bob@example.com' },
      ]);
      expect(calledArgs.sendUpdates).toBe('all');
      expect(result.attendeesNotified).toContain('alice@example.com');
    });

    it('should not send notifications when disabled', async () => {
      mockCalendarApi.events.insert.mockResolvedValue({
        data: { id: 'newEvent3', htmlLink: 'https://calendar.google.com' },
      });

      await calendarTools.calendar_create_event.handler({
        title: 'Silent Event',
        startTime: '2026-02-14T10:00:00+09:00',
        endTime: '2026-02-14T10:30:00+09:00',
        calendarId: 'primary',
        sendNotifications: false,
      });

      const calledArgs = mockCalendarApi.events.insert.mock.calls[0][0];
      expect(calledArgs.sendUpdates).toBe('none');
    });
  });

  describe('calendar_create_all_day_event - TC-C04: All-Day Events', () => {
    it('should create single-day event', async () => {
      mockCalendarApi.events.insert.mockResolvedValue({
        data: { id: 'allday1', htmlLink: 'https://calendar.google.com' },
      });

      const result = await calendarTools.calendar_create_all_day_event.handler({
        title: 'Company Holiday',
        date: '2026-03-01',
        calendarId: 'primary',
      });

      expect(result.success).toBe(true);
      const calledArgs = mockCalendarApi.events.insert.mock.calls[0][0];
      expect(calledArgs.requestBody.start.date).toBe('2026-03-01');
      expect(calledArgs.requestBody.end.date).toBe('2026-03-01');
    });

    it('should create multi-day event', async () => {
      mockCalendarApi.events.insert.mockResolvedValue({
        data: { id: 'allday2', htmlLink: 'https://calendar.google.com' },
      });

      await calendarTools.calendar_create_all_day_event.handler({
        title: 'Conference',
        date: '2026-03-01',
        endDate: '2026-03-03',
        calendarId: 'primary',
      });

      const calledArgs = mockCalendarApi.events.insert.mock.calls[0][0];
      expect(calledArgs.requestBody.start.date).toBe('2026-03-01');
      expect(calledArgs.requestBody.end.date).toBe('2026-03-03');
    });
  });

  describe('calendar_update_event - TC-C05: Event Updates', () => {
    it('should merge updates with existing event data', async () => {
      mockCalendarApi.events.get.mockResolvedValue({
        data: {
          summary: 'Original Title',
          description: 'Original Description',
          location: 'Room A',
          start: { dateTime: '2026-02-14T10:00:00+09:00' },
          end: { dateTime: '2026-02-14T11:00:00+09:00' },
        },
      });

      mockCalendarApi.events.update.mockResolvedValue({
        data: { id: 'event1', htmlLink: 'https://calendar.google.com' },
      });

      const result = await calendarTools.calendar_update_event.handler({
        eventId: 'event1',
        calendarId: 'primary',
        title: 'Updated Title',
      });

      expect(result.success).toBe(true);
      const calledArgs = mockCalendarApi.events.update.mock.calls[0][0];
      expect(calledArgs.requestBody.summary).toBe('Updated Title');
      // Should preserve existing description
      expect(calledArgs.requestBody.description).toBe('Original Description');
    });
  });

  describe('calendar_delete_event - TC-C06: Event Deletion', () => {
    it('should delete event with notification', async () => {
      mockCalendarApi.events.delete.mockResolvedValue({ data: {} });

      const result = await calendarTools.calendar_delete_event.handler({
        eventId: 'event1',
        calendarId: 'primary',
        sendNotifications: true,
      });

      expect(result.success).toBe(true);
      expect(mockCalendarApi.events.delete).toHaveBeenCalledWith(
        expect.objectContaining({
          eventId: 'event1',
          sendUpdates: 'all',
        })
      );
    });

    it('should delete event without notification', async () => {
      mockCalendarApi.events.delete.mockResolvedValue({ data: {} });

      await calendarTools.calendar_delete_event.handler({
        eventId: 'event1',
        calendarId: 'primary',
        sendNotifications: false,
      });

      const calledArgs = mockCalendarApi.events.delete.mock.calls[0][0];
      expect(calledArgs.sendUpdates).toBe('none');
    });
  });

  describe('calendar_quick_add - TC-C07: Quick Add', () => {
    it('should create event from natural language', async () => {
      mockCalendarApi.events.quickAdd.mockResolvedValue({
        data: {
          id: 'quick1',
          summary: 'Team meeting tomorrow at 3pm',
          start: { dateTime: '2026-02-14T15:00:00+09:00' },
          end: { dateTime: '2026-02-14T16:00:00+09:00' },
          htmlLink: 'https://calendar.google.com/event?id=quick1',
        },
      });

      const result = await calendarTools.calendar_quick_add.handler({
        text: 'Team meeting tomorrow at 3pm',
        calendarId: 'primary',
      });

      expect(result.success).toBe(true);
      expect(result.title).toBe('Team meeting tomorrow at 3pm');
    });
  });

  describe('calendar_find_free_time - TC-C08: Free/Busy Query', () => {
    it('should query free/busy with attendees', async () => {
      mockCalendarApi.freebusy.query.mockResolvedValue({
        data: {
          calendars: {
            primary: {
              busy: [
                { start: '2026-02-14T10:00:00Z', end: '2026-02-14T11:00:00Z' },
              ],
            },
          },
        },
      });

      const result = await calendarTools.calendar_find_free_time.handler({
        timeMin: '2026-02-14T09:00:00Z',
        timeMax: '2026-02-14T18:00:00Z',
        attendees: ['alice@example.com'],
      });

      const calledArgs = mockCalendarApi.freebusy.query.mock.calls[0][0];
      expect(calledArgs.requestBody.items).toEqual([
        { id: 'primary' },
        { id: 'alice@example.com' },
      ]);
      expect(result.calendars).toBeDefined();
    });
  });

  describe('calendar_respond_to_event - TC-C09: RSVP', () => {
    it('should respond as accepted', async () => {
      mockCalendarApi.events.get.mockResolvedValue({
        data: {
          attendees: [
            { email: 'me@example.com', self: true, responseStatus: 'needsAction' },
            { email: 'organizer@example.com', responseStatus: 'accepted' },
          ],
        },
      });

      mockCalendarApi.events.patch.mockResolvedValue({ data: {} });

      const result = await calendarTools.calendar_respond_to_event.handler({
        eventId: 'event1',
        calendarId: 'primary',
        response: 'accepted',
      });

      expect(result.success).toBe(true);
      const calledArgs = mockCalendarApi.events.patch.mock.calls[0][0];
      const attendees = calledArgs.requestBody.attendees;
      const me = attendees.find((a: { self?: boolean }) => a.self);
      expect(me.responseStatus).toBe('accepted');
    });
  });
});
