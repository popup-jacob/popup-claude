/**
 * Centralized message definitions for Google Workspace MCP tools.
 *
 * FR-S3-05b: Shared utility extraction
 * FR-S5-05: English-only with key-based structure for future i18n extensibility
 *
 * All user-facing messages should reference these constants via msg() helper.
 */

export const messages = {
  common: {
    success: "Success",
    failed: "Failed",
    created: "Created successfully",
    updated: "Updated successfully",
    deleted: "Deleted successfully",
    notFound: "Not found",
  },
  calendar: {
    eventCreated: (title: string) =>
      `Event "${title}" created successfully.`,
    eventUpdated: "Event updated successfully.",
    eventDeleted: "Event deleted successfully.",
    eventMoved: "Event moved successfully.",
    calendarCreated: (name: string) =>
      `Calendar "${name}" created successfully.`,
    calendarDeleted: "Calendar deleted successfully.",
    quickEventCreated: "Quick event created successfully.",
  },
  gmail: {
    emailSent: (to: string) => `Email sent to ${to}.`,
    draftSaved: "Draft saved successfully.",
    draftSent: "Draft sent successfully.",
    draftDeleted: "Draft deleted successfully.",
    labelAdded: "Label added successfully.",
    labelRemoved: "Label removed successfully.",
    markedRead: "Marked as read.",
    markedUnread: "Marked as unread.",
    movedToTrash: "Email moved to trash.",
    restoredFromTrash: "Email restored from trash.",
    attachmentFetched: "Attachment data retrieved (base64 encoded).",
  },
  drive: {
    folderCreated: (name: string) =>
      `Folder "${name}" created successfully.`,
    fileCopied: "File copied successfully.",
    fileMoved: "File moved successfully.",
    fileRenamed: (name: string) =>
      `File renamed to "${name}" successfully.`,
    fileDeleted: "File moved to trash.",
    fileRestored: "File restored from trash.",
    shared: (email: string, role: string) =>
      `Shared with ${email} as ${role}.`,
    linkShared: "Link sharing enabled.",
    unshared: (email: string) => `Sharing removed for ${email}.`,
    permissionNotFound: (email: string) =>
      `No sharing permission found for ${email}.`,
  },
  docs: {
    docCreated: (title: string) =>
      `Document "${title}" created successfully.`,
    textInserted: "Text inserted successfully.",
    textAppended: "Text appended successfully.",
    contentReplaced: "Content replaced successfully.",
    headerApplied: "Heading style applied successfully.",
  },
  sheets: {
    spreadsheetCreated: (title: string) =>
      `Spreadsheet "${title}" created successfully.`,
    valuesRead: "Values retrieved successfully.",
    valuesWritten: "Values written successfully.",
    valuesAppended: "Values appended successfully.",
    sheetAdded: "Sheet added successfully.",
    sheetDeleted: "Sheet deleted successfully.",
    formatApplied: "Formatting applied successfully.",
    chartCreated: "Chart created successfully.",
    pivotCreated: "Pivot table created successfully.",
  },
  slides: {
    presentationCreated: (title: string) =>
      `Presentation "${title}" created successfully.`,
    slideAdded: "Slide added successfully.",
    textAdded: "Text added successfully.",
    imageAdded: "Image added successfully.",
    tableAdded: "Table added successfully.",
    slideDeleted: "Slide deleted successfully.",
    speakerNotesSet: "Speaker notes updated successfully.",
  },
  errors: {
    authFailed:
      "Authentication failed. Please check credentials.",
    rateLimitExceeded:
      "Rate limit exceeded. Please try again later.",
    apiError: (message: string) => `API Error: ${message}`,
    networkError:
      "Network error. Please check your connection.",
    invalidRange: "Invalid range format.",
    invalidEmail: "Invalid email address.",
    invalidDate: "Invalid date format.",
    permissionDenied: "Permission denied.",
  },
};

/**
 * Helper to resolve message templates.
 * Handles both static strings and template functions.
 */
export function msg(
  template: string | ((...args: string[]) => string),
  ...args: string[]
): string {
  return typeof template === "function"
    ? template(...args)
    : template;
}
