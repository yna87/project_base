export class {{ table.name }} { 
    constructor(init?: Partial<{{ table.name }}>) {
        Object.assign(this, init);
    }

    {% for column in table.columns %}
    {{ column.name | camelcase }}?: {{ column.ts_type }};
    {% endfor %}
}

