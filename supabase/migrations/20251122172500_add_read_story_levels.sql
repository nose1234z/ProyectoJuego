
-- supabase/migrations/20251122172500_add_read_story_levels.sql

alter table profiles
add column read_story_levels int[] default array[]::int[];
