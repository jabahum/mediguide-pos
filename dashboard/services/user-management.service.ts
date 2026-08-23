import { getBackendClient } from "@/lib/backend-client";

export interface PageResult<T> {
  items: T[];
  page: number;
  per_page: number;
  total_items: number;
  total_pages: number;
}

export interface UserQuery {
  page?: number;
  per_page?: number;
  search?: string;
  status?: string;
  role_id?: string;
  sort?: "name" | "email" | "created_at" | "updated_at";
  order?: "asc" | "desc";
}

export interface RoleQuery {
  page?: number;
  per_page?: number;
  search?: string;
  is_active?: boolean;
}

const client = () => getBackendClient();

export const usersService = {
  requestPasswordReset(email: string) {
    return client().send<{
      accepted: boolean;
      delivery_accepted: boolean;
      development_token?: string;
    }>("/api/v2/auth/password-reset/request", {
      method: "POST",
      body: JSON.stringify({ email }),
    });
  },
  confirmPasswordReset(
    token: string,
    password: string,
    passwordConfirm: string,
  ) {
    return client().send<{ logged_out: boolean }>(
      "/api/v2/auth/password-reset/confirm",
      {
        method: "POST",
        body: JSON.stringify({
          token,
          password,
          password_confirm: passwordConfirm,
        }),
      },
    );
  },
  requestEmailVerification(email: string) {
    return client().send<{
      accepted: boolean;
      delivery_accepted: boolean;
      development_token?: string;
    }>("/api/v2/auth/email-verification/request", {
      method: "POST",
      body: JSON.stringify({ email }),
    });
  },
  confirmEmailVerification(token: string) {
    return client().send<{ verified: boolean }>(
      "/api/v2/auth/email-verification/confirm",
      { method: "POST", body: JSON.stringify({ token }) },
    );
  },
  list<T>(query: UserQuery = {}) {
    return client().send<PageResult<T>>("/api/v2/users", {
      query: { ...query },
    });
  },
  async all<T>(query: Omit<UserQuery, "page" | "per_page"> = {}) {
    const result = await this.list<T>({ ...query, page: 1, per_page: 100 });
    return result.items;
  },
  get<T>(id: string) {
    return client().send<T>(`/api/v2/users/${id}`);
  },
  create<T>(payload: object) {
    return client().send<T>("/api/v2/users", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  update<T>(id: string, payload: object) {
    return client().send<T>(`/api/v2/users/${id}`, {
      method: "PATCH",
      body: JSON.stringify(payload),
    });
  },
  delete(id: string) {
    return client().send<void>(`/api/v2/users/${id}`, { method: "DELETE" });
  },
  verify<T>(id: string) {
    return client().send<T>(`/api/v2/users/${id}/verification`, {
      method: "POST",
    });
  },
};

export const rolesService = {
  list<T>(query: RoleQuery = {}) {
    return client().send<PageResult<T>>("/api/v2/roles", {
      query: { ...query },
    });
  },
  async all<T>(query: Omit<RoleQuery, "page" | "per_page"> = {}) {
    const result = await this.list<T>({ ...query, page: 1, per_page: 100 });
    return result.items;
  },
  get<T>(id: string) {
    return client().send<T>(`/api/v2/roles/${id}`);
  },
  create<T>(payload: object) {
    return client().send<T>("/api/v2/roles", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
  update<T>(id: string, payload: object) {
    return client().send<T>(`/api/v2/roles/${id}`, {
      method: "PATCH",
      body: JSON.stringify(payload),
    });
  },
  delete(id: string) {
    return client().send<void>(`/api/v2/roles/${id}`, { method: "DELETE" });
  },
  permissions(id: string) {
    return client().send<Record<string, Record<string, string[]>>>(
      `/api/v2/roles/${id}/permissions`,
    );
  },
  updatePermissions<T>(id: string, permissions: Record<string, unknown>) {
    return client().send<T>(`/api/v2/roles/${id}/permissions`, {
      method: "PUT",
      body: JSON.stringify({ permissions }),
    });
  },
};
