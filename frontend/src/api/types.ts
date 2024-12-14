export interface ListResponse<T> {
    items: T[];
    count: number;
}

export interface SingleResponse<T> {
  data: T;
}

export type ApiResponse<T> = T extends any[] ? ListResponse<T[number]> : SingleResponse<T>;

