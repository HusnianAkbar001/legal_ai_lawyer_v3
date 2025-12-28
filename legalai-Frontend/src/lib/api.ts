// API Client for Legal Lawyer AI Backend
// import { CapacitorHttp, HttpResponse } from '@capacitor/http';
// import { Capacitor } from '@capacitor/core';
import { CapacitorHttp, HttpResponse, Capacitor } from '@capacitor/core';

const API_BASE_URL = 'http://192.168.10.3:5000/api/v1';

interface ApiResponse<T = any> {
  data?: T;
  error?: string;
  message?: string;
}

interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

// Platform-aware HTTP client
class PlatformHttpClient {
  static async request(
    url: string,
    options: {
      method?: string;
      headers?: Record<string, string>;
      data?: any;
    } = {}
  ): Promise<{
    ok: boolean;
    status: number;
    data: any;
  }> {
    // Use native HTTP on mobile platforms
    if (Capacitor.isNativePlatform()) {
      try {
        const response: HttpResponse = await CapacitorHttp.request({
          url,
          method: options.method || 'GET',
          headers: options.headers || {},
          data: options.data,
        });

        return {
          ok: response.status >= 200 && response.status < 300,
          status: response.status,
          data: response.data,
        };
      } catch (error) {
        throw new Error(error instanceof Error ? error.message : 'Network error');
      }
    }

    // Fallback to fetch for web
    try {
      const fetchOptions: RequestInit = {
        method: options.method || 'GET',
        headers: options.headers || {},
      };

      if (options.data) {
        fetchOptions.body = JSON.stringify(options.data);
      }

      const response = await fetch(url, fetchOptions);
      const data = await response.json();

      return {
        ok: response.ok,
        status: response.status,
        data,
      };
    } catch (error) {
      throw new Error(error instanceof Error ? error.message : 'Network error');
    }
  }

  static async uploadFile(
    url: string,
    file: File,
    headers: Record<string, string> = {}
  ): Promise<{ ok: boolean; data?: any; error?: string }> {
    // File upload always uses fetch (works on both platforms)
    try {
      const formData = new FormData();
      formData.append('file', file);

      const response = await fetch(url, {
        method: 'POST',
        headers,
        body: formData,
      });

      const data = await response.json();
      return {
        ok: response.ok,
        data: response.ok ? data : undefined,
        error: response.ok ? undefined : data.message || 'Upload failed',
      };
    } catch (error) {
      return {
        ok: false,
        error: error instanceof Error ? error.message : 'Upload failed',
      };
    }
  }

  static async downloadFile(
    url: string,
    headers: Record<string, string> = {}
  ): Promise<Blob | null> {
    try {
      const response = await fetch(url, { headers });
      return response.ok ? await response.blob() : null;
    } catch {
      return null;
    }
  }
}

class ApiClient {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;
  private safeMode: boolean = false;

  constructor() {
    this.loadTokens();
  }

  private loadTokens() {
    this.accessToken = localStorage.getItem('accessToken');
    this.refreshToken = localStorage.getItem('refreshToken');
  }

  setTokens(tokens: TokenPair) {
    this.accessToken = tokens.accessToken;
    this.refreshToken = tokens.refreshToken;
    localStorage.setItem('accessToken', tokens.accessToken);
    localStorage.setItem('refreshToken', tokens.refreshToken);
  }

  clearTokens() {
    this.accessToken = null;
    this.refreshToken = null;
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
  }

  getAccessToken() {
    return this.accessToken;
  }

  setSafeMode(enabled: boolean) {
    this.safeMode = enabled;
    localStorage.setItem('safeMode', String(enabled));
  }

  getSafeMode() {
    return localStorage.getItem('safeMode') === 'true';
  }

  private async request<T>(
    endpoint: string,
    options: {
      method?: string;
      data?: any;
      headers?: Record<string, string>;
    } = {}
  ): Promise<ApiResponse<T>> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    };

    if (this.accessToken) {
      headers['Authorization'] = `Bearer ${this.accessToken}`;
    }

    if (this.safeMode) {
      headers['X-Safe-Mode'] = '1';
    }

    try {
      const response = await PlatformHttpClient.request(`${API_BASE_URL}${endpoint}`, {
        method: options.method || 'GET',
        headers,
        data: options.data,
      });

      // Handle token refresh on 401
      if (response.status === 401 && this.refreshToken) {
        const refreshed = await this.refreshAccessToken();
        if (refreshed) {
          return this.request(endpoint, options);
        }
      }

      if (!response.ok) {
        return {
          error: response.data?.message || response.data?.error || 'Request failed',
        };
      }

      return { data: response.data };
    } catch (error) {
      return {
        error: error instanceof Error ? error.message : 'Network error',
      };
    }
  }

  private async refreshAccessToken(): Promise<boolean> {
    try {
      const response = await PlatformHttpClient.request(`${API_BASE_URL}/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        data: { refreshToken: this.refreshToken },
      });

      if (response.ok) {
        this.setTokens(response.data);
        return true;
      }
    } catch {
      // Refresh failed - silent fail
    }
    this.clearTokens();
    return false;
  }

  // Auth endpoints
  async signup(userData: {
    name: string;
    email: string;
    phone: string;
    cnic: string;
    password: string;
    city: string;
    gender: string;
    age: number;
    fatherName?: string;
    fatherCnic?: string;
    motherName?: string;
    motherCnic?: string;
    totalSiblings?: number;
    brothers?: number;
    sisters?: number;
    timezone?: string;
  }) {
    return this.request('/auth/signup', {
      method: 'POST',
      data: { ...userData, timezone: userData.timezone || 'Asia/Karachi' },
    });
  }

  async login(email: string, password: string) {
    const response = await this.request<TokenPair>('/auth/login', {
      method: 'POST',
      data: { email, password },
    });

    if (response.data) {
      this.setTokens(response.data);
    }
    return response;
  }

  async forgotPassword(email: string) {
    return this.request('/auth/forgot-password', {
      method: 'POST',
      data: { email },
    });
  }

  async resetPassword(token: string, newPassword: string) {
    return this.request('/auth/reset-password', {
      method: 'POST',
      data: { token, newPassword },
    });
  }

  async changePassword(currentPassword: string, newPassword: string, confirmPassword: string) {
    return this.request('/auth/change-password', {
      method: 'POST',
      data: { currentPassword, newPassword, confirmPassword },
    });
  }

  async verifyEmail(token: string) {
    return this.request(`/auth/verify-email?token=${token}`);
  }

  // User endpoints
  async getMe() {
    return this.request('/users/me');
  }

  async updateMe(data: Record<string, any>) {
    return this.request('/users/me', {
      method: 'PUT',
      data,
    });
  }

  async uploadAvatar(file: File) {
    const headers: Record<string, string> = {};
    if (this.accessToken) {
      headers['Authorization'] = `Bearer ${this.accessToken}`;
    }

    return PlatformHttpClient.uploadFile(`${API_BASE_URL}/users/me/avatar`, file, headers);
  }

  // Bookmarks
  async getBookmarks() {
    return this.request('/users/me/bookmarks');
  }

  async addBookmark(itemType: string, itemId: number) {
    return this.request('/users/me/bookmarks', {
      method: 'POST',
      data: { itemType, itemId },
    });
  }

  async deleteBookmark(bookmarkId: number) {
    return this.request(`/users/me/bookmarks/${bookmarkId}`, {
      method: 'DELETE',
    });
  }

  // Activity
  async logActivity(eventType: string, payload: Record<string, any>) {
    return this.request('/users/me/activity', {
      method: 'POST',
      data: { eventType, payload },
    });
  }

  async getActivity() {
    return this.request('/users/me/activity');
  }

  // Rights
  async getRights(category?: string, language: string = 'en') {
    const params = new URLSearchParams({ language });
    if (category) params.append('category', category);
    return this.request(`/rights?${params}`);
  }

  async getRight(rightId: number) {
    return this.request(`/rights/${rightId}`);
  }

  // Templates
  async getTemplates(category?: string, language: string = 'en') {
    const params = new URLSearchParams({ language });
    if (category) params.append('category', category);
    return this.request(`/templates?${params}`);
  }

  async getTemplate(templateId: number) {
    return this.request(`/templates/${templateId}`);
  }

  // Pathways
  async getPathways(category?: string, language: string = 'en') {
    const params = new URLSearchParams({ language });
    if (category) params.append('category', category);
    return this.request(`/pathways?${params}`);
  }

  async getPathway(pathwayId: number) {
    return this.request(`/pathways/${pathwayId}`);
  }

  // Checklists
  async getChecklistCategories() {
    return this.request('/checklists/categories');
  }

  async getChecklistItems(categoryId?: number) {
    const params = categoryId ? `?categoryId=${categoryId}` : '';
    return this.request(`/checklists/items${params}`);
  }

  // Chat
  async sendMessage(question: string, language: string = 'en', conversationId?: number) {
    return this.request('/chat/ask', {
      method: 'POST',
      data: { question, language, conversationId },
    });
  }

  async getConversations(page: number = 1, limit: number = 20) {
    return this.request(`/chat/conversations?page=${page}&limit=${limit}`);
  }

  async getConversationMessages(conversationId: number, page: number = 1, limit: number = 30) {
    return this.request(`/chat/conversations/${conversationId}/messages?page=${page}&limit=${limit}`);
  }

  async renameConversation(conversationId: number, title: string) {
    return this.request(`/chat/conversations/${conversationId}`, {
      method: 'PUT',
      data: { title },
    });
  }

  async deleteConversation(conversationId: number) {
    return this.request(`/chat/conversations/${conversationId}`, {
      method: 'DELETE',
    });
  }

  // Drafts
  async generateDraft(templateId: number, answers: Record<string, string>, userSnapshot: Record<string, string>) {
    return this.request('/drafts/generate', {
      method: 'POST',
      data: { templateId, answers, userSnapshot },
    });
  }

  async getDrafts() {
    return this.request('/drafts');
  }

  async getDraft(draftId: number) {
    return this.request(`/drafts/${draftId}`);
  }

  async deleteDraft(draftId: number) {
    return this.request(`/drafts/${draftId}`, {
      method: 'DELETE',
    });
  }

  async exportDraft(draftId: number, format: 'txt' | 'pdf' | 'docx') {
    const headers: Record<string, string> = {};
    if (this.accessToken) {
      headers['Authorization'] = `Bearer ${this.accessToken}`;
    }

    return PlatformHttpClient.downloadFile(
      `${API_BASE_URL}/drafts/${draftId}/export?format=${format}`,
      headers
    );
  }

  // Reminders
  async getReminders() {
    return this.request('/reminders');
  }

  async createReminder(data: { title: string; notes?: string; scheduledAt: string; timezone?: string }) {
    return this.request('/reminders', {
      method: 'POST',
      data: { ...data, timezone: data.timezone || 'Asia/Karachi' },
    });
  }

  async updateReminder(reminderId: number, data: Partial<{ title: string; notes: string; isDone: boolean }>) {
    return this.request(`/reminders/${reminderId}`, {
      method: 'PUT',
      data,
    });
  }

  async deleteReminder(reminderId: number) {
    return this.request(`/reminders/${reminderId}`, {
      method: 'DELETE',
    });
  }

  async registerDeviceToken(platform: 'android' | 'ios', token: string) {
    return this.request('/reminders/register-device-token', {
      method: 'POST',
      data: { platform, token },
    });
  }

  // Content (offline caching)
  async getManifest() {
    return this.request('/content/manifest');
  }

  // Support
  async submitContactMessage(data: {
    fullName: string;
    email: string;
    phone: string;
    subject: string;
    description: string;
  }) {
    return this.request('/support/contact', {
      method: 'POST',
      data,
    });
  }

  async submitFeedback(rating: number, comment: string) {
    return this.request('/support/feedback', {
      method: 'POST',
      data: { rating, comment },
    });
  }

  // Lawyers
  async getLawyers(page: number = 1, perPage: number = 20) {
    return this.request(`/lawyers?page=${page}&perPage=${perPage}`);
  }
}

export const api = new ApiClient();
export type { ApiResponse, TokenPair };
// // API Client for Legal Lawyer AI Backend
// const API_BASE_URL = 'http://192.168.10.3:5000/api/v1';

// interface ApiResponse<T = any> {
//   data?: T;
//   error?: string;
//   message?: string;
// }

// interface TokenPair {
//   accessToken: string;
//   refreshToken: string;
// }

// class ApiClient {
//   private accessToken: string | null = null;
//   private refreshToken: string | null = null;
//   private safeMode: boolean = false;

//   constructor() {
//     this.loadTokens();
//   }

//   private loadTokens() {
//     this.accessToken = localStorage.getItem('accessToken');
//     this.refreshToken = localStorage.getItem('refreshToken');
//   }

//   setTokens(tokens: TokenPair) {
//     this.accessToken = tokens.accessToken;
//     this.refreshToken = tokens.refreshToken;
//     localStorage.setItem('accessToken', tokens.accessToken);
//     localStorage.setItem('refreshToken', tokens.refreshToken);
//   }

//   clearTokens() {
//     this.accessToken = null;
//     this.refreshToken = null;
//     localStorage.removeItem('accessToken');
//     localStorage.removeItem('refreshToken');
//   }

//   getAccessToken() {
//     return this.accessToken;
//   }

//   setSafeMode(enabled: boolean) {
//     this.safeMode = enabled;
//     localStorage.setItem('safeMode', String(enabled));
//   }

//   getSafeMode() {
//     return localStorage.getItem('safeMode') === 'true';
//   }

//   private async request<T>(
//     endpoint: string,
//     options: RequestInit = {}
//   ): Promise<ApiResponse<T>> {
//     const headers: HeadersInit = {
//       'Content-Type': 'application/json',
//       ...(options.headers || {}),
//     };

//     if (this.accessToken) {
//       (headers as Record<string, string>)['Authorization'] = `Bearer ${this.accessToken}`;
//     }

//     if (this.safeMode) {
//       (headers as Record<string, string>)['X-Safe-Mode'] = '1';
//     }

//     try {
//       const response = await fetch(`${API_BASE_URL}${endpoint}`, {
//         ...options,
//         headers,
//       });

//       if (response.status === 401 && this.refreshToken) {
//         const refreshed = await this.refreshAccessToken();
//         if (refreshed) {
//           return this.request(endpoint, options);
//         }
//       }

//       const data = await response.json();
      
//       if (!response.ok) {
//         return { error: data.message || data.error || 'Request failed' };
//       }

//       return { data };
//     } catch (error) {
//       return { error: error instanceof Error ? error.message : 'Network error' };
//     }
//   }

//   private async refreshAccessToken(): Promise<boolean> {
//     try {
//       const response = await fetch(`${API_BASE_URL}/auth/refresh`, {
//         method: 'POST',
//         headers: { 'Content-Type': 'application/json' },
//         body: JSON.stringify({ refreshToken: this.refreshToken }),
//       });

//       if (response.ok) {
//         const data = await response.json();
//         this.setTokens(data);
//         return true;
//       }
//     } catch {
//       // Refresh failed
//     }
//     this.clearTokens();
//     return false;
//   }

//   // Auth endpoints
//   async signup(userData: {
//     name: string;
//     email: string;
//     phone: string;
//     cnic: string;
//     password: string;
//     city: string;
//     gender: string;
//     age: number;
//     fatherName?: string;
//     fatherCnic?: string;
//     motherName?: string;
//     motherCnic?: string;
//     totalSiblings?: number;
//     brothers?: number;
//     sisters?: number;
//     timezone?: string;
//   }) {
//     return this.request('/auth/signup', {
//       method: 'POST',
//       body: JSON.stringify({ ...userData, timezone: userData.timezone || 'Asia/Karachi' }),
//     });
//   }

//   async login(email: string, password: string) {
//     const response = await this.request<TokenPair>('/auth/login', {
//       method: 'POST',
//       body: JSON.stringify({ email, password }),
//     });
    
//     if (response.data) {
//       this.setTokens(response.data);
//     }
//     return response;
//   }

//   async forgotPassword(email: string) {
//     return this.request('/auth/forgot-password', {
//       method: 'POST',
//       body: JSON.stringify({ email }),
//     });
//   }

//   async resetPassword(token: string, newPassword: string) {
//     return this.request('/auth/reset-password', {
//       method: 'POST',
//       body: JSON.stringify({ token, newPassword }),
//     });
//   }

//   async changePassword(currentPassword: string, newPassword: string, confirmPassword: string) {
//     return this.request('/auth/change-password', {
//       method: 'POST',
//       body: JSON.stringify({ currentPassword, newPassword, confirmPassword }),
//     });
//   }

//   async verifyEmail(token: string) {
//     return this.request(`/auth/verify-email?token=${token}`);
//   }

//   // User endpoints
//   async getMe() {
//     return this.request('/users/me');
//   }

//   async updateMe(data: Record<string, any>) {
//     return this.request('/users/me', {
//       method: 'PUT',
//       body: JSON.stringify(data),
//     });
//   }

//   async uploadAvatar(file: File) {
//     const formData = new FormData();
//     formData.append('file', file);
    
//     const response = await fetch(`${API_BASE_URL}/users/me/avatar`, {
//       method: 'POST',
//       headers: {
//         'Authorization': `Bearer ${this.accessToken}`,
//       },
//       body: formData,
//     });
    
//     return response.ok ? { data: await response.json() } : { error: 'Upload failed' };
//   }

//   // Bookmarks
//   async getBookmarks() {
//     return this.request('/users/me/bookmarks');
//   }

//   async addBookmark(itemType: string, itemId: number) {
//     return this.request('/users/me/bookmarks', {
//       method: 'POST',
//       body: JSON.stringify({ itemType, itemId }),
//     });
//   }

//   async deleteBookmark(bookmarkId: number) {
//     return this.request(`/users/me/bookmarks/${bookmarkId}`, {
//       method: 'DELETE',
//     });
//   }

//   // Activity
//   async logActivity(eventType: string, payload: Record<string, any>) {
//     return this.request('/users/me/activity', {
//       method: 'POST',
//       body: JSON.stringify({ eventType, payload }),
//     });
//   }

//   async getActivity() {
//     return this.request('/users/me/activity');
//   }

//   // Rights
//   async getRights(category?: string, language: string = 'en') {
//     const params = new URLSearchParams({ language });
//     if (category) params.append('category', category);
//     return this.request(`/rights?${params}`);
//   }

//   async getRight(rightId: number) {
//     return this.request(`/rights/${rightId}`);
//   }

//   // Templates
//   async getTemplates(category?: string, language: string = 'en') {
//     const params = new URLSearchParams({ language });
//     if (category) params.append('category', category);
//     return this.request(`/templates?${params}`);
//   }

//   async getTemplate(templateId: number) {
//     return this.request(`/templates/${templateId}`);
//   }

//   // Pathways
//   async getPathways(category?: string, language: string = 'en') {
//     const params = new URLSearchParams({ language });
//     if (category) params.append('category', category);
//     return this.request(`/pathways?${params}`);
//   }

//   async getPathway(pathwayId: number) {
//     return this.request(`/pathways/${pathwayId}`);
//   }

//   // Checklists
//   async getChecklistCategories() {
//     return this.request('/checklists/categories');
//   }

//   async getChecklistItems(categoryId?: number) {
//     const params = categoryId ? `?categoryId=${categoryId}` : '';
//     return this.request(`/checklists/items${params}`);
//   }

//   // Chat
//   async sendMessage(question: string, language: string = 'en', conversationId?: number) {
//     return this.request('/chat/ask', {
//       method: 'POST',
//       body: JSON.stringify({ question, language, conversationId }),
//     });
//   }

//   async getConversations(page: number = 1, limit: number = 20) {
//     return this.request(`/chat/conversations?page=${page}&limit=${limit}`);
//   }

//   async getConversationMessages(conversationId: number, page: number = 1, limit: number = 30) {
//     return this.request(`/chat/conversations/${conversationId}/messages?page=${page}&limit=${limit}`);
//   }

//   async renameConversation(conversationId: number, title: string) {
//     return this.request(`/chat/conversations/${conversationId}`, {
//       method: 'PUT',
//       body: JSON.stringify({ title }),
//     });
//   }

//   async deleteConversation(conversationId: number) {
//     return this.request(`/chat/conversations/${conversationId}`, {
//       method: 'DELETE',
//     });
//   }

//   // Drafts
//   async generateDraft(templateId: number, answers: Record<string, string>, userSnapshot: Record<string, string>) {
//     return this.request('/drafts/generate', {
//       method: 'POST',
//       body: JSON.stringify({ templateId, answers, userSnapshot }),
//     });
//   }

//   async getDrafts() {
//     return this.request('/drafts');
//   }

//   async getDraft(draftId: number) {
//     return this.request(`/drafts/${draftId}`);
//   }

//   async deleteDraft(draftId: number) {
//     return this.request(`/drafts/${draftId}`, {
//       method: 'DELETE',
//     });
//   }

//   async exportDraft(draftId: number, format: 'txt' | 'pdf' | 'docx') {
//     const response = await fetch(`${API_BASE_URL}/drafts/${draftId}/export?format=${format}`, {
//       headers: {
//         'Authorization': `Bearer ${this.accessToken}`,
//       },
//     });
    
//     if (response.ok) {
//       return response.blob();
//     }
//     return null;
//   }

//   // Reminders
//   async getReminders() {
//     return this.request('/reminders');
//   }

//   async createReminder(data: { title: string; notes?: string; scheduledAt: string; timezone?: string }) {
//     return this.request('/reminders', {
//       method: 'POST',
//       body: JSON.stringify({ ...data, timezone: data.timezone || 'Asia/Karachi' }),
//     });
//   }

//   async updateReminder(reminderId: number, data: Partial<{ title: string; notes: string; isDone: boolean }>) {
//     return this.request(`/reminders/${reminderId}`, {
//       method: 'PUT',
//       body: JSON.stringify(data),
//     });
//   }

//   async deleteReminder(reminderId: number) {
//     return this.request(`/reminders/${reminderId}`, {
//       method: 'DELETE',
//     });
//   }

//   async registerDeviceToken(platform: 'android' | 'ios', token: string) {
//     return this.request('/reminders/register-device-token', {
//       method: 'POST',
//       body: JSON.stringify({ platform, token }),
//     });
//   }

//   // Content (offline caching)
//   async getManifest() {
//     return this.request('/content/manifest');
//   }

//   // Support
//   async submitContactMessage(data: {
//     fullName: string;
//     email: string;
//     phone: string;
//     subject: string;
//     description: string;
//   }) {
//     return this.request('/support/contact', {
//       method: 'POST',
//       body: JSON.stringify(data),
//     });
//   }

//   async submitFeedback(rating: number, comment: string) {
//     return this.request('/support/feedback', {
//       method: 'POST',
//       body: JSON.stringify({ rating, comment }),
//     });
//   }

//   // Lawyers
//   async getLawyers(page: number = 1, perPage: number = 20) {
//     return this.request(`/lawyers?page=${page}&perPage=${perPage}`);
//   }
// }

// export const api = new ApiClient();
// export type { ApiResponse, TokenPair };
