from jinja2 import Environment, FileSystemLoader
import os
from typing import List, Dict
from markdown_parser import MarkdownParser, InflectionUtils

class TypeScriptGenerator:
    def __init__(self, template_dir='templates'):
        self.env = Environment(
            loader=FileSystemLoader(template_dir),
            trim_blocks=True,
            lstrip_blocks=True
        )
        self.markdown_parser = MarkdownParser()
        # カスタムフィルターを登録
        self.env.filters['pascalcase'] = InflectionUtils.to_pascal_case
        self.env.filters['camelcase'] = InflectionUtils.to_camel_case
        self.env.filters['snakecase'] = InflectionUtils.to_snake_case
    
    def generate_from_markdown(self, markdown_path: str, output_dir: str):
        with open(markdown_path, 'r', encoding='utf-8') as f:
            markdown_content = f.read()
        
        tables = self.markdown_parser.parse_markdown(markdown_content)
        
        models_dir = os.path.join(output_dir, 'models')
        api_dir = os.path.join(output_dir, 'api')
        os.makedirs(models_dir, exist_ok=True)
        os.makedirs(api_dir, exist_ok=True)
        
        for table in tables:
            model_content = self.generate_model(table)
            model_path = os.path.join(models_dir, f'{table["name"].lower()}.ts')
            with open(model_path, 'w', encoding='utf-8') as f:
                f.write(model_content)
        
        api_content = self.generate_api(tables)
        api_path = os.path.join(api_dir, 'api.ts')
        with open(api_path, 'w', encoding='utf-8') as f:
            f.write(api_content)
    
    def generate_model(self, table_definition: dict) -> str:
        template = self.env.get_template('typescript/model.ts')
        return template.render(table=table_definition)
    
    def generate_api(self, tables: List[Dict]) -> str:
        template = self.env.get_template('typescript/api.ts')
        return template.render(tables=tables)

if __name__ == '__main__':
    generator = TypeScriptGenerator()
    generator.generate_from_markdown('../doc/erd.md', '../frontend/src')
