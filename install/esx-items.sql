-- Use this only on ESX inventories that store items in the `items` table.
-- Adjust weight columns if your inventory schema differs.

INSERT IGNORE INTO `items` (`name`, `label`, `weight`) VALUES
    ('cardboard_sign', 'Cardboard Sign', 350),
    ('begging_cup', 'Begging Cup', 120);
