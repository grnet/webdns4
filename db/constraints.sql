ALTER TABLE `records` ADD CONSTRAINT `records_ibfk_1` FOREIGN KEY (`domain_id`)
REFERENCES `domains` (`id`) ON DELETE CASCADE;
