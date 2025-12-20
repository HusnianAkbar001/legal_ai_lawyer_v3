// API Client for Legal Lawyer AI Backend
// const API_BASE_URL = 'http://localhost:5000/api/v1';
const API_BASE_URL = 'http://172.16.18.152:5000/api/v1';

interface ApiResponse<T = any> {
  data?: T;
  error?: string;
  message?: string;
}

interface TokenPair {
  accessToken: string;
  refreshToken: string;
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
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    };

    if (this.accessToken) {
      (headers as Record<string, string>)['Authorization'] = `Bearer ${this.accessToken}`;
    }

    if (this.safeMode) {
      (headers as Record<string, string>)['X-Safe-Mode'] = '1';
    }

    try {
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        ...options,
        headers,
      });

      if (response.status === 401 && this.refreshToken) {
        const refreshed = await this.refreshAccessToken();
        if (refreshed) {
          return this.request(endpoint, options);
        }
      }

      const data = await response.json();
      
      if (!response.ok) {
        return { error: data.message || data.error || 'Request failed' };
      }

      return { data };
    } catch (error) {
      return { error: error instanceof Error ? error.message : 'Network error' };
    }
  }

  private async refreshAccessToken(): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken: this.refreshToken }),
      });

      if (response.ok) {
        const data = await response.json();
        this.setTokens(data);
        return true;
      }
    } catch {
      // Refresh failed
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
      body: JSON.stringify({ ...userData, timezone: userData.timezone || 'Asia/Karachi' }),
    });
  }

  async login(email: string, password: string) {
    const response = await this.request<TokenPair>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    
    if (response.data) {
      this.setTokens(response.data);
    }
    return response;
  }

  async forgotPassword(email: string) {
    return this.request('/auth/forgot-password', {
      method: 'POST',
      body: JSON.stringify({ email }),
    });
  }

  async resetPassword(token: string, newPassword: string) {
    return this.request('/auth/reset-password', {
      method: 'POST',
      body: JSON.stringify({ token, newPassword }),
    });
  }

  async changePassword(currentPassword: string, newPassword: string, confirmPassword: string) {
    return this.request('/auth/change-password', {
      method: 'POST',
      body: JSON.stringify({ currentPassword, newPassword, confirmPassword }),
    });
  }

  // User endpoints
  async getMe() {
    return this.request('/users/me');
  }

  async updateMe(data: Record<string, any>) {
    return this.request('/users/me', {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async uploadAvatar(file: File) {
    const formData = new FormData();
    formData.append('file', file);
    
    const response = await fetch(`${API_BASE_URL}/users/me/avatar`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.accessToken}`,
      },
      body: formData,
    });
    
    return response.ok ? { data: await response.json() } : { error: 'Upload failed' };
  }

  // Bookmarks
  async getBookmarks() {
    return this.request('/users/me/bookmarks');
  }

  async addBookmark(itemType: string, itemId: number) {
    return this.request('/users/me/bookmarks', {
      method: 'POST',
      body: JSON.stringify({ itemType, itemId }),
    });
  }

  async deleteBookmark(bookmarkId: number) {
    return this.request(`/users/me/bookmarks/${bookmarkId}`, {
      method: 'DELETE',
    });
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
      body: JSON.stringify({ question, language, conversationId }),
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
      body: JSON.stringify({ title }),
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
      body: JSON.stringify({ templateId, answers, userSnapshot }),
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
    const response = await fetch(`${API_BASE_URL}/drafts/${draftId}/export?format=${format}`, {
      headers: {
        'Authorization': `Bearer ${this.accessToken}`,
      },
    });
    
    if (response.ok) {
      return response.blob();
    }
    return null;
  }

  // Reminders
  async getReminders() {
    return this.request('/reminders');
  }

  async createReminder(data: { title: string; notes?: string; scheduledAt: string; timezone?: string }) {
    return this.request('/reminders', {
      method: 'POST',
      body: JSON.stringify({ ...data, timezone: data.timezone || 'Asia/Karachi' }),
    });
  }

  async updateReminder(reminderId: number, data: Partial<{ title: string; notes: string; isDone: boolean }>) {
    return this.request(`/reminders/${reminderId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async deleteReminder(reminderId: number) {
    return this.request(`/reminders/${reminderId}`, {
      method: 'DELETE',
    });
  }

  // Content (offline caching)
  async getManifest() {
    return this.request('/content/manifest');
  }
}

export const api = new ApiClient();
export type { ApiResponse, TokenPair };
