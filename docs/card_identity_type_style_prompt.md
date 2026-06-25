# Card Identity and Type Styling Prompt

Refine the Conquest Cartes card set without changing card balance or mechanics.

Preserve the identity of the existing illustration library by restoring each
artwork's original card name wherever one card owns that art. When artwork is
shared, keep one exact original name and give variants names derived from the same
subject while making the mechanical role understandable.

Keep IDs, definitions, and `art_id` mappings data-driven. Do not hardcode
card-specific behavior or presentation in UI code.

Give resource, action, and victory cards subtly different dark medieval surface
colors:

- Resources: warm coin-pouch umber
- Actions: cool smoked walnut
- Victory cards: restrained oxblood walnut

Preserve affordability and playability borders, disabled states, cursor feedback,
tooltips, hover animation, artwork, and text contrast. Apply the same type
treatment to card previews.

Update automated tests and documentation. Run the Godot rules and UI smoke tests,
perform a Web export, and commit and push the completed work.
