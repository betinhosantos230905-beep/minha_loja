"""DADOS DE DEMONSTRAÇÃO - totalmente fictícios (opcionais).

Usados somente por `popular_banco.py` para testar a aplicação em desenvolvimento.
Não são necessários para o sistema funcionar: o cardápio real é cadastrado
pelo painel administrativo.
"""

CATEGORIES = [
    {"id": 1, "name": "Categoria Exemplo 1", "order": 1, "active": True},
    {"id": 2, "name": "Categoria Exemplo 2", "order": 2, "active": True},
    {"id": 3, "name": "Categoria Exemplo 3", "order": 3, "active": True},
]


def _group(gid, name, min_, max_, options):
    return {
        "id": gid, "name": name, "min": min_, "max": max_,
        "options": [
            {"id": f"{gid}-{i}", "name": n, "price": p}
            for i, (n, p) in enumerate(options, 1)
        ],
    }


TAMANHO = _group("g-tamanho", "Tamanho", 1, 1,
                 [("Pequeno", 0), ("Grande", 5.00)])
ADICIONAIS = _group("g-adicionais", "Adicionais", 0, 2,
                    [("Adicional exemplo A", 2.00), ("Adicional exemplo B", 3.00)])

PRODUCTS = [
    {"id": 101, "category_id": 1, "name": "Produto Exemplo 1", "price": 10.00,
     "available": True, "featured": True, "prep_minutes": 15,
     "description": "Descrição fictícia do produto de exemplo.",
     "option_groups": [TAMANHO, ADICIONAIS]},
    {"id": 102, "category_id": 1, "name": "Produto Exemplo 2", "price": 12.00,
     "available": True, "featured": False, "prep_minutes": 15,
     "description": "Descrição fictícia do produto de exemplo.",
     "option_groups": [TAMANHO]},
    {"id": 201, "category_id": 2, "name": "Produto Exemplo 3", "price": 8.00,
     "available": True, "featured": False, "prep_minutes": 10,
     "description": "Descrição fictícia do produto de exemplo.",
     "option_groups": []},
    {"id": 202, "category_id": 2, "name": "Produto Exemplo 4 (indisponível)", "price": 9.00,
     "available": False, "featured": False, "prep_minutes": 10,
     "description": "Exemplo de produto marcado como indisponível.",
     "option_groups": []},
    {"id": 301, "category_id": 3, "name": "Produto Exemplo 5", "price": 5.00,
     "available": True, "featured": False, "prep_minutes": None,
     "description": "Descrição fictícia do produto de exemplo.",
     "option_groups": [ADICIONAIS]},
]
