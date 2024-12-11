export class {{ table.name }} { 
    {% for column in table.columns %}
    {{ column.name | camelcase }}: {{ column.ts_type }};
    {% endfor %}

    constructor(init?: Partial<{{ table.name }}>) {
        Object.assign(this, init);
    }
}

