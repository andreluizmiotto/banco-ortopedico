insert into catalog.equipment_types (code, name, is_active, display_order)
values
  ('CR', 'Cadeira de rodas', true, 1),
  ('CM', 'Cama hospitalar', true, 2),
  ('CB', 'Cadeira de banho', true, 3),
  ('AN', 'Andador', true, 4),
  ('MU', 'Muletas', true, 5),
  ('CO', 'Colchão para cama hospitalar', true, 6),
  ('CI', 'Cadeira infantil ou adaptada', true, 7),
  ('BO', 'Bota ortopédica', true, 8),
  ('TI', 'Tipoia de braço', true, 9),
  ('SS', 'Suporte para soro', true, 10),
  ('AE', 'Assento sanitário elevado', true, 11),
  ('BA', 'Banheira ou apoio para banho', true, 12),
  ('OU', 'Outros', true, 13),
  ('PE', 'Peruca', false, 14)
on conflict (code) do update
set
  name = excluded.name,
  is_active = excluded.is_active,
  display_order = excluded.display_order;
