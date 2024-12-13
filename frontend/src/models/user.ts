export class User { 
    id: number;
    name: string;
    email: string;
    createdAt: Date;
    updatedAt: Date;

    constructor(init?: Partial<User>) {
        Object.assign(this, init);
    }
}
