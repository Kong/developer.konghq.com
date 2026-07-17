Keep the following constraints in mind when configuring a form:
* A form can have a maximum of 20 fields.
* Text field values can have a maximum of 256 characters.
* A form must contain exactly one submit field.
* Each field has a `name` (a lowercase slug of letters, digits, underscores, and hyphens) that acts as its permanent identifier. Once set, it can't be changed. Renaming a field's label doesn't change its `name`, so previously collected data always stays linked to the field.
* Built-in fields (`full_name` and `email` on the developer registration form) can have their `placeholder`, `description`, and `required` properties edited, but their type, label, and name can't be changed, and they can't be removed.
