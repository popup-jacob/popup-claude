import { z } from "zod";
import { getGoogleServices } from "../auth/oauth.js";

/**
 * Calendar 도구 정의
 */
export const calendarTools = {
  calendar_list_calendars: {
    description: "사용 가능한 캘린더 목록을 조회합니다",
    schema: {},
    handler: async () => {
      const { calendar } = await getGoogleServices();

      const response = await calendar.calendarList.list();
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
    description: "캘린더 일정 목록을 조회합니다",
    schema: {
      calendarId: z.string().optional().default("primary").describe("캘린더 ID (기본: primary)"),
      timeMin: z.string().optional().describe("시작 시간 (ISO 형식)"),
      timeMax: z.string().optional().describe("종료 시간 (ISO 형식)"),
      maxResults: z.number().optional().default(10).describe("최대 결과 수"),
      query: z.string().optional().describe("검색어"),
    },
    handler: async ({ calendarId, timeMin, timeMax, maxResults, query }: {
      calendarId: string;
      timeMin?: string;
      timeMax?: string;
      maxResults: number;
      query?: string;
    }) => {
      const { calendar } = await getGoogleServices();

      const now = new Date();
      const defaultTimeMin = timeMin || now.toISOString();
      const defaultTimeMax = timeMax || new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000).toISOString();

      const response = await calendar.events.list({
        calendarId,
        timeMin: defaultTimeMin,
        timeMax: defaultTimeMax,
        maxResults,
        singleEvents: true,
        orderBy: "startTime",
        q: query,
      });

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
    description: "특정 일정의 상세 정보를 조회합니다",
    schema: {
      calendarId: z.string().optional().default("primary").describe("캘린더 ID"),
      eventId: z.string().describe("일정 ID"),
    },
    handler: async ({ calendarId, eventId }: { calendarId: string; eventId: string }) => {
      const { calendar } = await getGoogleServices();

      const response = await calendar.events.get({
        calendarId,
        eventId,
      });

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
    description: "새 캘린더 일정을 생성합니다",
    schema: {
      title: z.string().describe("일정 제목"),
      startTime: z.string().describe("시작 시간 (ISO 형식 또는 'YYYY-MM-DD HH:mm')"),
      endTime: z.string().describe("종료 시간 (ISO 형식 또는 'YYYY-MM-DD HH:mm')"),
      description: z.string().optional().describe("일정 설명"),
      location: z.string().optional().describe("장소"),
      attendees: z.array(z.string()).optional().describe("참석자 이메일 목록"),
      calendarId: z.string().optional().default("primary").describe("캘린더 ID"),
      sendNotifications: z.boolean().optional().default(true).describe("참석자에게 알림 발송 여부"),
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

      const parseTime = (timeStr: string) => {
        if (timeStr.includes("T")) return timeStr;
        const [date, time] = timeStr.split(" ");
        return `${date}T${time}:00+09:00`;
      };

      const event = {
        summary: title,
        description,
        location,
        start: {
          dateTime: parseTime(startTime),
          timeZone: "Asia/Seoul",
        },
        end: {
          dateTime: parseTime(endTime),
          timeZone: "Asia/Seoul",
        },
        attendees: attendees?.map((email) => ({ email })),
      };

      const response = await calendar.events.insert({
        calendarId,
        requestBody: event,
        sendUpdates: sendNotifications ? "all" : "none",
      });

      return {
        success: true,
        eventId: response.data.id,
        link: response.data.htmlLink,
        message: `일정 "${title}"이 생성되었습니다.`,
        attendeesNotified: attendees && sendNotifications ? `${attendees.join(", ")}에게 초대가 발송되었습니다.` : null,
      };
    },
  },

  calendar_create_all_day_event: {
    description: "종일 일정을 생성합니다",
    schema: {
      title: z.string().describe("일정 제목"),
      date: z.string().describe("날짜 (YYYY-MM-DD)"),
      endDate: z.string().optional().describe("종료 날짜 (YYYY-MM-DD, 여러 날인 경우)"),
      description: z.string().optional().describe("일정 설명"),
      calendarId: z.string().optional().default("primary").describe("캘린더 ID"),
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

      const response = await calendar.events.insert({
        calendarId,
        requestBody: event,
      });

      return {
        success: true,
        eventId: response.data.id,
        link: response.data.htmlLink,
        message: `종일 일정 "${title}"이 생성되었습니다.`,
      };
    },
  },

  calendar_update_event: {
    description: "기존 캘린더 일정을 수정합니다",
    schema: {
      eventId: z.string().describe("일정 ID"),
      calendarId: z.string().optional().default("primary").describe("캘린더 ID"),
      title: z.string().optional().describe("새 제목"),
      startTime: z.string().optional().describe("새 시작 시간"),
      endTime: z.string().optional().describe("새 종료 시간"),
      description: z.string().optional().describe("새 설명"),
      location: z.string().optional().describe("새 장소"),
      attendees: z.array(z.string()).optional().describe("새 참석자 목록"),
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

      const existing = await calendar.events.get({
        calendarId,
        eventId,
      });

      const parseTime = (timeStr: string) => {
        if (timeStr.includes("T")) return timeStr;
        const [date, time] = timeStr.split(" ");
        return `${date}T${time}:00+09:00`;
      };

      const updatedEvent: any = {
        summary: title || existing.data.summary,
        description: description ?? existing.data.description,
        location: location ?? existing.data.location,
        start: startTime
          ? { dateTime: parseTime(startTime), timeZone: "Asia/Seoul" }
          : existing.data.start,
        end: endTime
          ? { dateTime: parseTime(endTime), timeZone: "Asia/Seoul" }
          : existing.data.end,
      };

      if (attendees) {
        updatedEvent.attendees = attendees.map((email) => ({ email }));
      }

      const response = await calendar.events.update({
        calendarId,
        eventId,
        requestBody: updatedEvent,
        sendUpdates: attendees ? "all" : "none",
      });

      return {
        success: true,
        eventId: response.data.id,
        link: response.data.htmlLink,
        message: "일정이 수정되었습니다.",
      };
    },
  },

  calendar_delete_event: {
    description: "캘린더 일정을 삭제합니다",
    schema: {
      eventId: z.string().describe("일정 ID"),
      calendarId: z.string().optional().default("primary").describe("캘린더 ID"),
      sendNotifications: z.boolean().optional().default(true).describe("참석자에게 알림 발송 여부"),
    },
    handler: async ({ eventId, calendarId, sendNotifications }: {
      eventId: string;
      calendarId: string;
      sendNotifications: boolean;
    }) => {
      const { calendar } = await getGoogleServices();

      await calendar.events.delete({
        calendarId,
        eventId,
        sendUpdates: sendNotifications ? "all" : "none",
      });

      return {
        success: true,
        message: "일정이 삭제되었습니다.",
      };
    },
  },

  calendar_quick_add: {
    description: "자연어로 빠르게 일정을 추가합니다",
    schema: {
      text: z.string().describe("일정 설명 (예: '내일 오후 3시 팀 미팅')"),
      calendarId: z.string().optional().default("primary").describe("캘린더 ID"),
    },
    handler: async ({ text, calendarId }: { text: string; calendarId: string }) => {
      const { calendar } = await getGoogleServices();

      const response = await calendar.events.quickAdd({
        calendarId,
        text,
      });

      return {
        success: true,
        eventId: response.data.id,
        title: response.data.summary,
        start: response.data.start?.dateTime || response.data.start?.date,
        end: response.data.end?.dateTime || response.data.end?.date,
        link: response.data.htmlLink,
        message: `일정이 생성되었습니다: ${response.data.summary}`,
      };
    },
  },

  calendar_find_free_time: {
    description: "특정 시간대의 빈 시간을 찾습니다",
    schema: {
      timeMin: z.string().describe("검색 시작 시간 (ISO 형식)"),
      timeMax: z.string().describe("검색 종료 시간 (ISO 형식)"),
      attendees: z.array(z.string()).optional().describe("함께 확인할 참석자 이메일"),
    },
    handler: async ({ timeMin, timeMax, attendees }: {
      timeMin: string;
      timeMax: string;
      attendees?: string[];
    }) => {
      const { calendar } = await getGoogleServices();

      const items = [{ id: "primary" }];
      if (attendees) {
        attendees.forEach((email) => items.push({ id: email }));
      }

      const response = await calendar.freebusy.query({
        requestBody: {
          timeMin,
          timeMax,
          items,
        },
      });

      return {
        timeMin,
        timeMax,
        calendars: response.data.calendars,
      };
    },
  },

  calendar_respond_to_event: {
    description: "일정 초대에 응답합니다 (수락/거절/미정)",
    schema: {
      eventId: z.string().describe("일정 ID"),
      calendarId: z.string().optional().default("primary").describe("캘린더 ID"),
      response: z.enum(["accepted", "declined", "tentative"]).describe("응답 (accepted, declined, tentative)"),
    },
    handler: async ({ eventId, calendarId, response }: {
      eventId: string;
      calendarId: string;
      response: string;
    }) => {
      const { calendar } = await getGoogleServices();

      // 현재 사용자 이메일 가져오기
      const event = await calendar.events.get({
        calendarId,
        eventId,
      });

      const attendees = event.data.attendees || [];
      const me = attendees.find((a) => a.self);

      if (me) {
        me.responseStatus = response;
      }

      await calendar.events.patch({
        calendarId,
        eventId,
        requestBody: {
          attendees,
        },
      });

      const responseText = {
        accepted: "수락",
        declined: "거절",
        tentative: "미정",
      }[response];

      return {
        success: true,
        message: `일정에 "${responseText}"으로 응답했습니다.`,
      };
    },
  },
};
