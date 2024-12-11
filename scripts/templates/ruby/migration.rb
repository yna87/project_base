require './models/{{ table.name | snakecase }}.rb'

class Create{{ table.plural_name | pascalcase }}
  def up
    {{ table.name | pascalcase }}.create_table()
  end

  def down
    db = SQLite3::Database.new('db/development.sqlite3')
    db.execute('DROP TABLE IF EXISTS {{ table.plural_name | snakecase }};')
  end
end
