// The supported backend endpoints are selected with VITE_DATA_MODE=api.
// Features without backend endpoints continue to use their existing frontend services.
export * from "./mock/mockAuthService.js";
export * from "./mock/mockLearningService.js";
export * from "./mock/mockCommunicationService.js";
export { askMentor, generateQuiz, checkMessage } from "./api/mlServiceAdapter.js";

import { isBackendMode, dataModeError, apiListAssignments, apiGetAssignment, apiCreateAssignment, apiSubmitAssignment, apiListMaterials, apiAddMaterial, apiListNotifications, apiMarkNotificationRead, apiMarkAllNotificationsRead, apiListCalendarEvents, apiListCalendarMonth } from "./api/backendAdapter.js";
import { listAssignments as mockListAssignments, getAssignment as mockGetAssignment, createAssignment as mockCreateAssignment, submitAssignment as mockSubmitAssignment, listMaterials as mockListMaterials, addMaterial as mockAddMaterial, listCalendarEvents as mockListCalendarEvents } from "./mock/mockLearningService.js";
import { listNotifications as mockListNotifications, markNotificationRead as mockMarkNotificationRead, markAllNotificationsRead as mockMarkAllNotificationsRead } from "./mock/mockCommunicationService.js";

const selectService = (apiService, mockService, args) => {
  if (dataModeError) return Promise.reject(new Error(dataModeError));
  return (isBackendMode ? apiService : mockService)(...args);
};

export const listAssignments = (...args) => selectService(apiListAssignments, mockListAssignments, args);
export const getAssignment = (...args) => selectService(apiGetAssignment, mockGetAssignment, args);
export const createAssignment = (...args) => selectService(apiCreateAssignment, mockCreateAssignment, args);
export const submitAssignment = (...args) => selectService(apiSubmitAssignment, mockSubmitAssignment, args);
export const listMaterials = (...args) => selectService(apiListMaterials, mockListMaterials, args);
export const addMaterial = (...args) => selectService(apiAddMaterial, mockAddMaterial, args);
export const listNotifications = (...args) => selectService(apiListNotifications, mockListNotifications, args);
export const markNotificationRead = (...args) => selectService(apiMarkNotificationRead, mockMarkNotificationRead, args);
export const markAllNotificationsRead = (...args) => selectService(apiMarkAllNotificationsRead, mockMarkAllNotificationsRead, args);
export const listCalendarEvents = (...args) => selectService(apiListCalendarEvents, mockListCalendarEvents, args);
export const listCalendarMonth = (...args) => selectService(apiListCalendarMonth, mockListCalendarEvents, args);
