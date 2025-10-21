from odoo import models, fields


class AutoTest(models.Model):
    _name = "auto.test"
    _description = "Auto Install Test"

    name = fields.Char(string="Name", required=True)