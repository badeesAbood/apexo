# apexo

Dental clinic management system

## Todo

- dashboard : TODO: payments tab
- Permissions for each staff member
- Web: my appointments
- Web: my images
- Web: my payments
- Web: me + QR code scanner
- Xata Login?? it's not very user friendly
- Xata Client??



DATABASE Migration:

```json
[
    {
        "create_table": {
            "name": "main",
            "columns": [
                {
                    "name": "data",
                    "type": "jsonb",
                    "pk": false,
                    "unique": false,
                    "default": "'{}'::jsonb",
                    "nullable": false
                },
                {
                    "name": "store",
                    "type": "text"
                },
                {
                    "name": "imgs",
                    "type": "xata.xata_file_array",
                    "pk": false,
                    "unique": false,
                    "comment": "{\"xata.file.dpa\":true}",
                    "nullable": false
                }
            ]
        }
    }
]
```