class {{ table.name }}
  attr_accessor :id{% for column in table.columns %}{% if column.name != 'id' %}, :{{ column.name | lower }}{% endif %}{% endfor %}
  
  def self.db
    @db ||= SQLite3::Database.new('db/development.sqlite3')
    @db.results_as_hash = true
    @db
  end

  def self.create_table
    db.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS {{ table.plural_name | lower }} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        {% for column in table.columns %}
        {% if column.name not in ['id', 'created_at', 'updated_at'] %}
        {{ column.name | lower }} {{ column.sqlite_type }},
        {% endif %}
        {% endfor %}
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    SQL
  end

  def self.all
    db.execute("SELECT * FROM {{ table.plural_name | lower }}")
  end

  def self.find(id)
    db.execute("SELECT * FROM {{ table.plural_name | lower }} WHERE id = ?", id).first
  end

  def self.create(params)
    columns = [
      {% for column in table.columns %}
      {% if column.name not in ['id', 'created_at', 'updated_at'] %}
      '{{ column.name | lower }}'{% if not loop.last %},{% endif %}
      {% endif %}
      {% endfor %}
    ]
    values = columns.map { |col| params[col.to_sym] }
    
    db.execute(
      "INSERT INTO {{ table.plural_name | lower }} (#{columns.join(', ')}) VALUES (#{Array.new(columns.length, '?').join(', ')})",
      values
    )
    find(db.last_insert_row_id)
  end

  def self.update(id, params)
    columns = [
      {% for column in table.columns %}
      {% if column.name not in ['id', 'created_at', 'updated_at'] %}
      '{{ column.name | lower }}'{% if not loop.last %},{% endif %}
      {% endif %}
      {% endfor %}
    ]
    sets = columns.map { |col| "#{col} = ?" }.join(', ')
    values = columns.map { |col| params[col.to_sym] } + [id]
    
    db.execute(
      "UPDATE {{ table.plural_name | lower }} SET #{sets}, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
      values
    )
    find(id)
  end

  def self.delete(id)
    db.execute("DELETE FROM {{ table.plural_name | lower }} WHERE id = ?", id)
  end
end
