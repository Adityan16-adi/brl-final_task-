// The supported backend endpoints are selected with VITE_DATA_MODE=api.
// Features without backend endpoints continue to use their existing frontend services.
export * from "./mock/mockAuthService.js";
export * from "./mock/mockLearningService.js";
export * from "./mock/mockCommunicationService.js";
export * from "./mock/mockStudyService.js";

import { isBackendMode, apiListAssignments, apiGetAssignment, apiCreateAssignment, apiSubmitAssignment, apiListMaterials, apiAddMaterial, apiListNotifications, apiMarkNotificationRead, apiMarkAllNotificationsRead, apiListCalendarEvents } from "./api/backendAdapter.js";
import { listAssignments as mockListAssignments, getAssignment as mockGetAssignment, createAssignment as mockCreateAssignment, submitAssignment as mockSubmitAssignment, listMaterials as mockListMaterials, addMaterial as mockAddMaterial, listCalendarEvents as mockListCalendarEvents } from "./mock/mockLearningService.js";
import { listNotifications as mockListNotifications, markNotificationRead as mockMarkNotificationRead, markAllNotificationsRead as mockMarkAllNotificationsRead } from "./mock/mockCommunicationService.js";

export const listAssignments = (...args) => isBackendMode ? apiListAssignments(...args) : mockListAssignments(...args);
export const getAssignment = (...args) => isBackendMode ? apiGetAssignment(...args) : mockGetAssignment(...args);
export const createAssignment = (...args) => isBackendMode ? apiCreateAssignment(...args) : mockCreateAssignment(...args);
export const submitAssignment = (...args) => isBackendMode ? apiSubmitAssignment(...args) : mockSubmitAssignment(...args);
export const listMaterials = (...args) => isBackendMode ? apiListMaterials(...args) : mockListMaterials(...args);
export const addMaterial = (...args) => isBackendMode ? apiAddMaterial(...args) : mockAddMaterial(...args);
export const listNotifications = (...args) => isBackendMode ? apiListNotifications(...args) : mockListNotifications(...args);
export const markNotificationRead = (...args) => isBackendMode ? apiMarkNotificationRead(...args) : mockMarkNotificationRead(...args);
export const markAllNotificationsRead = (...args) => isBackendMode ? apiMarkAllNotificationsRead(...args) : mockMarkAllNotificationsRead(...args);
export const listCalendarEvents = (...args) => isBackendMode ? apiListCalendarEvents(...args) : mockListCalendarEvents(...args);
