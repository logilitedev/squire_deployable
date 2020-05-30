-- Alter Columns for  CreatedBy & Resolved By Joust
ALTER TABLE jousts ADD COLUMN created_by bigint(20);
ALTER TABLE jousts ADD COLUMN resolved_by bigint(20);

-- Set Default created By as Admin
update jousts  set created_by = 3403;

-- Set Default Resolved By as Admin
update jousts set resolved_by = 3403
	where id in(
		Select joust_id from jousts_questions
		where question_id not in(
			Select distinct question_id from  answer_options where answer_option_outcome_id > 1
		)
 );