class Create{{ table.plural_name | pascalcase }} < ActiveRecord::Migration[8.0]
  def change
    create_table :{{ table.plural_name | lower }} do |t|
      {% for column in table.columns %}
      {% if column.name not in ['id', 'created_at', 'updated_at'] %}
      t.{{ column.ruby_type }} :{{ column.name | lower }}
      {% endif %}
      {% endfor %}

      t.timestamps
    end
  end
end

