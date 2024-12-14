from jinja2 import Environment, FileSystemLoader
import os
import glob
import re
from typing import List, Dict
from markdown_parser import MarkdownParser, InflectionUtils
from datetime import datetime, timedelta

class RubyGenerator:
    def __init__(self, template_dir='templates'):
        self.env = Environment(
            loader=FileSystemLoader(template_dir),
            trim_blocks=True,
            lstrip_blocks=True
        )
        self.markdown_parser = MarkdownParser()
        self.env.filters['pascalcase'] = InflectionUtils.to_pascal_case
        self.env.filters['camelcase'] = InflectionUtils.to_camel_case
        self.env.filters['snakecase'] = InflectionUtils.to_snake_case
        self.current_timestamp = None
    
    def _map_type_to_ruby(self, ts_type: str) -> str:
        type_mapping = {
            'number': 'integer',
            'string': 'string',
            'Date': 'datetime',
            'boolean': 'boolean'
        }
        return type_mapping.get(ts_type, 'string')

    def _map_type_to_sqlite(self, ruby_type: str) -> str:
        type_mapping = {
            'integer': 'INTEGER',
            'string': 'TEXT',
            'datetime': 'DATETIME',
            'boolean': 'BOOLEAN',
            'decimal': 'DECIMAL',
            'float': 'FLOAT'
        }
        return type_mapping.get(ruby_type, 'TEXT')

    def _remove_existing_migration(self, output_dir: str, table_name: str):
        """
        Remove existing migration files for a given table name
        """
        migration_dir = os.path.join(output_dir, 'db/migrate')
        if not os.path.exists(migration_dir):
            return

        # マイグレーションファイルのパターン: [timestamp]_create_[table_name].rb
        pattern = os.path.join(migration_dir, f'*_create_{table_name}.rb')
        existing_files = glob.glob(pattern)
        
        for file_path in existing_files:
            try:
                os.remove(file_path)
            except OSError as e:
                print(f"Error removing file {file_path}: {e}")

    def _generate_timestamp(self) -> str:
        """
        Generate unique timestamp for migration files
        Each call returns a timestamp 1 second later than the previous one
        """
        if self.current_timestamp is None:
            self.current_timestamp = datetime.now()
        else:
            self.current_timestamp += timedelta(seconds=1)
        
        return self.current_timestamp.strftime('%Y%m%d%H%M%S')

    def generate_from_markdown(self, markdown_path: str, output_dir: str):
        """Generate Ruby files from markdown definition"""
        self.current_timestamp = None
        
        with open(markdown_path, 'r', encoding='utf-8') as f:
            markdown_content = f.read()
        
        tables = self.markdown_parser.parse_markdown(markdown_content)

        self.save_files({'config/routes.rb': self.generate_routes(tables)}, output_dir)
        
        for table in tables:
            for column in table['columns']:
                ruby_type = self._map_type_to_ruby(column['ts_type'])
                sqlite_type = self._map_type_to_sqlite(ruby_type)
                column.update({
                    'ruby_type': ruby_type,
                    'sqlite_type': sqlite_type
                })
            
            # マイグレーションファイルを生成する前に既存のファイルを削除
            self._remove_existing_migration(output_dir, table['plural_name'].lower())
            
            files = self.generate_files(table)
            self.save_files(files, output_dir)

    def generate_files(self, table_definition: dict) -> dict:
        model_name = table_definition['name'].lower()
        plural_name = table_definition['plural_name'].lower()
        
        return {
            f'app/models/{model_name}.rb': self.generate_model(table_definition),
            f'app/controllers/api/v1/{plural_name}_controller.rb': self.generate_controller(table_definition),
            f'db/migrate/{self._generate_timestamp()}_create_{plural_name}.rb': self.generate_migration(table_definition)
        }

    def generate_model(self, table_definition: dict) -> str:
        template = self.env.get_template('ruby/model.rb')
        return template.render(table=table_definition)
    
    def generate_controller(self, table_definition: dict) -> str:
        template = self.env.get_template('ruby/controller.rb')
        return template.render(table=table_definition)
    
    def generate_routes(self, tables: List[Dict]) -> str:
        template = self.env.get_template('ruby/routes.rb')
        return template.render(tables=tables)
    
    def generate_migration(self, table_definition: dict) -> str:
        template = self.env.get_template('ruby/migration.rb')
        return template.render(table=table_definition)
    
    def save_files(self, files: dict, output_dir: str):
        for path, content in files.items():
            full_path = os.path.join(output_dir, f'{path}')
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(content)

if __name__ == '__main__':
    generator = RubyGenerator()
    generator.generate_from_markdown('../doc/erd.md', '../backend')

