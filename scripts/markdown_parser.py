from typing import List, Dict
import re

class InflectionUtils:
    """Utility class for handling singular/plural word forms"""
    
    # 不規則な単数形/複数形のマッピング
    IRREGULAR_WORDS = {
        'person': 'people',
        'child': 'children',
        'foot': 'feet',
        'man': 'men',
        'woman': 'women',
        'tooth': 'teeth',
        'mouse': 'mice',
        'datum': 'data'
    }
    
    @classmethod
    def singularize(cls, word: str) -> str:
        """単数形に変換"""
        # 不規則形のチェック(逆引き)
        for singular, plural in cls.IRREGULAR_WORDS.items():
            if word.lower() == plural:
                return singular
        
        # 基本的な複数形のルールを逆適用
        if word.endswith('ies'):
            return word[:-3] + 'y'
        elif word.endswith('es'):
            if word.endswith('sses') or word.endswith('shes') or word.endswith('ches'):
                return word[:-2]
            return word[:-1]
        elif word.endswith('s'):
            return word[:-1]
        
        return word

    @classmethod
    def pluralize(cls, word: str) -> str:
        """複数形に変換"""
        # 不規則形のチェック
        if word.lower() in cls.IRREGULAR_WORDS:
            return cls.IRREGULAR_WORDS[word.lower()]
        
        # 基本的な複数形のルール
        if word.endswith('y'):
            if word[-2].lower() not in 'aeiou':
                return word[:-1] + 'ies'
            return word + 's'
        elif word.endswith(('s', 'sh', 'ch', 'x', 'z')):
            return word + 'es'
        else:
            return word + 's'
    
    @classmethod
    def to_camel_case(cls, snake_str: str) -> str:
        """スネークケースからキャメルケースに変換"""
        # 最初の_の前はそのまま、それ以降は_を削除して次の文字を大文字に
        components = snake_str.split('_')
        return components[0] + ''.join(x.title() for x in components[1:])
    
    @classmethod
    def to_snake_case(cls, camel_str: str) -> str:
        return re.sub(r'(?<!^)(?=[A-Z])', '_', camel_str).lower()
    
    @classmethod
    def to_pascal_case(cls, snake_str: str) -> str:
        """スネークケースからパスカルケースに変換"""
        # まず、キャメルケースに変換
        camel = InflectionUtils.to_camel_case(snake_str)
        # 最初の文字を大文字にして返す
        return camel[0].upper() + camel[1:]

class MarkdownParser:
    def parse_markdown(self, markdown_content: str) -> List[Dict]:
        tables = []
        current_table = None
        
        for line in markdown_content.split('\n'):
            line = line.strip()
            
            if line.startswith('## '):
                if current_table:
                    tables.append(current_table)
                table_name = line[3:]
                singular_name = InflectionUtils.singularize(table_name)
                current_table = {
                    'name': singular_name,
                    'plural_name': table_name,
                    'columns': []
                }
            
            elif line.startswith('- ') and current_table:
                column_def = line[2:]
                name, type_def = column_def.split(': ')
                ts_type = self._map_type_to_typescript(type_def)
                current_table['columns'].append({
                    'name': name,
                    'ts_type': ts_type
                })
        
        if current_table:
            tables.append(current_table)
            
        return tables
    
    def _map_type_to_typescript(self, md_type: str) -> str:
        """Map markdown type definitions to TypeScript types"""
        type_mapping = {
            'number': 'number',
            'string': 'string',
            'Date': 'Date',
            'boolean': 'boolean',
        }
        return type_mapping.get(md_type, 'any')
