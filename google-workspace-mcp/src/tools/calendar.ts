import { z } from "zod";
import { getGoogleServices } from "../auth/oauth.js";
import { getTimezone, parseTime } from "../utils/time.js";
import { withRetry } from "../utils/retry.js";
import { messages, msg } from "../utils/messages.js";

/**
 * Calendar tool definitions
 */
export const calendarTools = {
  calendar_list_calendars: {
    description: "List available calendars",
    schema: {},
    handler: async () => {
      const { calendar } = await getGoogleServices();

      const response = await withRetry(() => calendar.calendarList.list());
      const calendars = response.data.items || [];

      return {
        calendars: calendars.map((cal) => ({
          id: cal.id,
          name: cal.summary,
          description: cal.description,
          primary: cal.primary,
          accessRole: cal.accessRole,
          backgroundColor: cal.backgroundColor,
        })),
      };
    },
  },

  calendar_list_events: {
    description: "List calendar events",
    schema: {
      calendarId: z
        .string()
        .optional()
        .default("primary")
        .describe("Calendar ID (default: primary)"),
      timeMin: z.string().optional().describe("Start time (ISO format)"),
      timeMax: z.string().optional().describe("End time (ISO format)"),
      maxResults: z.number().optional().default(10).describe("Maximum number of results"),
      query: z.string().optional().describe("Search query"),
    },
    handler: async ({
      calendarId,
      timeMin,
      timeMax,
      maxResults,
      query,
    }: {
      calendarId: string;
      timeMin?: string;
      timeMax?: string;
      maxResults: number;
      query?: string;
    }) => {
      const { calendar } = await getGoogleServices();

      const now = new Date();
      const defaultTimeMin = timeMin || now.toISOString();
      const defaultTimeMax =
        timeMax || new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000).toISOString();

      const response = await withRetry(() =>
        calendar.events.list({
          calendarId,
          timeMin: defaultTimeMin,
          timeMax: defaultTimeMax,
          maxResults,
          singleEvents: true,
          orderBy: "startTime",
          q: query,
        })
      );

      const events = response.data.items || [];

      return {
        total: events.length,
        events: events.map((event) => ({
          id: event.id,
          title: event.summary,
          description: event.description,
          start: event.start?.dateTime || event.start?.date,
          end: event.end?.dateTime || event.end?.date,
          location: event.location,
          attendees: event.attendees?.map((a) => ({
            email: a.email,
            name: a.displayName,
            responseStatus: a.responseStatus,
          })),
          link: event.htmlLink,
          status: event.status,
          creator: event.creator?.email,
          organizer: event.organizer?.email,
        })),
      };
    },
  },

  calendar_get_event: {
    description: "Get detailed information about a specific event",
    schema: {
      calendarId: z.string().optional().default("primary").describe("Calendar ID"),
      eventId: z.string().describe("Event ID"),
    },
    handler: async ({ calendarId, eventId }: { calendarId: string; eventId: string }) => {
      const { calendar } = await getGoogleServices();

      const response = await withRetry(() =>
        calendar.events.get({
          calendarId,
          eventId,
        })
      );

      const event = response.data;

      return {
        id: event.id,
        title: event.summary,
        description: event.description,
        start: event.start?.dateTime || event.start?.date,
        end: event.end?.dateTime || event.end?.date,
        location: event.location,
        attendees: event.attendees?.map((a) => ({
          email: a.email,
          name: a.displayName,
          responseStatus: a.responseStatus,
          organizer: a.organizer,
        })),
        link: event.htmlLink,
        status: event.status,
        recurrence: event.recurrence,
        reminders: event.reminders,
        conferenceData: event.conferenceData,
      };
    },
  },

  calendar_create_event: {
    description: "Create a new calendar event",
    schema: {
      title: z.string().describe("Event title"),
      startTime: z.string().describe("Start time (ISO format or 'YYYY-MM-DD HH:mm')"),
      endTime: z.string().describe("End time (ISO format or 'YYYY-MM-DD HH:mm')"),
      description: z.string().optional().describe("Event description"),
      location: z.string().optional().describe("Location"),
      attendees: z.array(z.string()).optional().describe("Attendee email list"),
      calendarId: z.string().optional().default("primary").describe("Calendar ID"),
      sendNotifications: z
        .boolean()
        .optional()
        .default(true)
        .describe("Send notification to attendees"),
    },
    handler: async ({
      title,
      startTime,
      endTime,
      description,
      location,
      attendees,
      calendarId,
      sendNotifications,
    }: {
      title: string;
      startTime: string;
      endTime: string;
      description?: string;
      location?: string;
      attendees?: string[];
      calendarId: string;
      sendNotifications: boolean;
    }) => {
      const { calendar } = await getGoogleServices();

      // FR-S4-03: Dynamic timezone from Intl API / TIMEZONE env
      const tz = getTimezone();

      const event = {
        summary: title,
        description,
        location,
        start: {
          dateTime: parseTime(startTime),
          timeZone: tz,
        },
        end: {
          dateTime: parseTime(endTime),
          timeZone: tz,
        },
        attendees: attendees?.map((email) => ({ email })),
      };

      const response = await withRetry(() =>
        calendar.events.insert({
          calendarId,
          requestBody: event,
          sendUpdates: sendNotifications ? "all" : "none",
        })
      );

      return {
        success: true,
        eventId: response.data.id,
        link: response.data.htmlLink,
        message: msg(messages.calendar.eventCreated, title),
        attendeesNotified:
          attendees && sendNotifications ? `Invitation sent to ${attendees.join(", ")}.` : null,
      };
    },
  },

  calendar_create_all_day_event: {
    description: "Create an all-day event",
    schema: {
      title: z.string().describe("Event title"),
      date: z.string().describe("Date (YYYY-MM-DD)"),
      endDate: z.string().optional().describe("End date (YYYY-MM-DD, for multi-day events)"),
      description: z.string().optional().describe("Event description"),
      calendarId: z.string().optional().default("primary").describe("Calendar ID"),
    },
    handler: async ({
      title,
      date,
      endDate,
      description,
      calendarId,
    }: {
      title: string;
      date: string;
      endDate?: string;
      description?: string;
      calendarId: string;
    }) => {
      const { calendar } = await getGoogleServices();

      const event = {
        summary: title,
        description,
        start: {
          date: date,
        },
        end: {
          date: endDate || date,
        },
      };

      const response = await withRetry(() =>
        calendar.events.insert({
          calendarId,
          requestBody: event,
        })
      );

      return {
        success: true,
        eventId: response.data.id,
        link: response.data.htmlLink,
        message: msg(messages.calendar.eventCreated, title),
      };
    },
  },

  calendar_update_event: {
    description: "Update an existing calendar event",
    schema: {
      eventId: z.string().describe("Event ID"),
      calendarId: z.string().optional().default("primary").describe("Calendar ID"),
      title: z.string().optional().describe("New title"),
      startTime: z.string().optional().describe("New start time"),
      endTime: z.string().optional().describe("New end time"),
      description: z.string().optional().describe("New description"),
      location: z.string().optional().describe("New location"),
      attendees: z.array(z.string()).optional().describe("New attendee list"),
    },
    handler: async ({
      eventId,
      calendarId,
      title,
      startTime,
      endTime,
      description,
      location,
      attendees,
    }: {
      eventId: string;
      calendarId: string;
      title?: string;
      startTime?: string;
      endTime?: string;
      description?: string;
      location?: string;
      attendees?: string[];
    }) => {
      const { calendar } = await getGoogleServices();

      const existing = await withRetry(() =>
        calendar.events.get({
          calendarId,
          eventId,
        })
      );

      // FR-S4-03: Dynamic timezone
      const tz = getTimezone();

      // FR-S3-07: Typed event object instead of any
      const updatedEvent: Record<string, unknown> = {
        summary: title || existing.data.summary,
        description: description ?? existing.data.description,
        location: location ?? existing.data.location,
        start: startTime ? { dateTime: parseTime(startTime), timeZone: tz } : existing.data.start,
        end: endTime ? { dateTime: parseTime(endTime), timeZone: tz } : existing.data.end,
      };

      if (attendees) {
        updatedEvent.attendees = attendees.map((email) => ({ email }));
      }

      const response = await withRetry(() =>
        calendar.events.update({
          calendarId,
          eventId,
          requestBody: updatedEvent,
          sendUpdates: attendees ? "all" : "none",
        })
      );

      return {
        success: true,
        eventId: response.data.id,
        link: response.data.htmlLink,
        message: messages.calendar.eventUpdated,
      };
    },
  },

  calendar_delete_event: {
    description: "Delete a calendar event",
    schema: {
      eventId: z.string().describe("Event ID"),
      calendarId: z.string().optional().default("primary").describe("Calendar ID"),
      sendNotifications: z
        .boolean()
        .optional()
        .default(true)
        .describe("Send notification to attendees"),
    },
    handler: async ({
      eventId,
      calendarId,
      sendNotifications,
    }: {
      eventId: string;
      calendarId: string;
      sendNotifications: boolean;
    }) => {
      const { calendar } = await getGoogleServices();

      await withRetry(() =>
        calendar.events.delete({
          calendarId,
          eventId,
          sendUpdates: sendNotifications ? "all" : "none",
        })
      );

      return {
        success: true,
        message: messages.calendar.eventDeleted,
      };
    },
  },

  calendar_quick_add: {
    description: "Quickly add an event using natural language",
    schema: {
      text: z.string().describe("Event description (e.g. 'team meeting tomorrow at 3pm')"),
      calendarId: z.string().optional().default("primary").describe("Calendar ID"),
    },
    handler: async ({ text, calendarId }: { text: string; calendarId: string }) => {
      const { calendar } = await getGoogleServices();

      const response = await withRetry(() =>
        calendar.events.quickAdd({
          calendarId,
          text,
        })
      );

      return {
        success: true,
        eventId: response.data.id,
        title: response.data.summary,
        start: response.data.start?.dateTime || response.data.start?.date,
        end: response.data.end?.dateTime || response.data.end?.date,
        link: response.data.htmlLink,
        message: `Event created: ${response.data.summary}`,
      };
    },
  },

  calendar_find_free_time: {
    description: "Find free time in a given time range",
    schema: {
      timeMin: z.string().describe("Search start time (ISO format)"),
      timeMax: z.string().describe("Search end time (ISO format)"),
      attendees: z.array(z.string()).optional().describe("Attendee emails to check availability"),
    },
    handler: async ({
      timeMin,
      timeMax,
      attendees,
    }: {
      timeMin: string;
      timeMax: string;
      attendees?: string[];
    }) => {
      const { calendar } = await getGoogleServices();

      const items = [{ id: "primary" }];
      if (attendees) {
        attendees.forEach((email) => items.push({ id: email }));
      }

      const response = await withRetry(() =>
        calendar.freebusy.query({
          requestBody: {
            timeMin,
            timeMax,
            items,
          },
        })
      );

      return {
        timeMin,
        timeMax,
        calendars: response.data.calendars,
      };
    },
  },

  calendar_respond_to_event: {
    description: "Respond to an event invitation (accept/decline/tentative)",
    schema: {
      eventId: z.string().describe("Event ID"),
      calendarId: z.string().optional().default("primary").describe("Calendar ID"),
      response: z
        .enum(["accepted", "declined", "tentative"])
        .describe("Response (accepted, declined, tentative)"),
    },
    handler: async ({
      eventId,
      calendarId,
      response,
    }: {
      eventId: string;
      calendarId: string;
      response: string;
    }) => {
      const { calendar } = await getGoogleServices();

      const event = await withRetry(() =>
        calendar.events.get({
          calendarId,
          eventId,
        })
      );

      const attendees = event.data.attendees || [];
      const me = attendees.find((a) => a.self);

      if (me) {
        me.responseStatus = response;
      }

      await withRetry(() =>
        calendar.events.patch({
          calendarId,
          eventId,
          requestBody: {
            attendees,
          },
        })
      );

      return {
        success: true,
        message: `Responded to event as "${response}".`,
      };
    },
  },
};
