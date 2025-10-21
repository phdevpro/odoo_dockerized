{
    "name": "Auto Install Test",
    "version": "18.0.1.0.0",
    "summary": "Simple module to verify automatic installation via entrypoint",
    "category": "Tools",
    "author": "Odoo Dockerized",
    "license": "LGPL-3",
    "depends": ["base"],
    "data": [
        "security/ir.model.access.csv",
        "views/auto_test_menu.xml"
    ],
    "application": False,
    "installable": True
}