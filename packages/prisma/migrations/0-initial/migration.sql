---------------------------------- 00-initial-schema ----------------------------------
-- rapidform super admin
create user rapidform_admin with superuser createdb createrole replication bypassrls;

create schema if not exists extensions;
create extension if not exists "uuid-ossp"      with schema extensions;
create extension if not exists pgcrypto         with schema extensions;
-- create extension if not exists pgjwt            with schema extensions;

-- Set up auth roles for the developer
create role anon                nologin noinherit;
create role authenticated       nologin noinherit; -- "logged in" user: web_user, app_user, etc
create role service_role        nologin noinherit bypassrls; -- allow developers to create JWT's that bypass their policies

create user authenticator noinherit;
grant anon              to authenticator;
grant authenticated     to authenticator;
grant service_role      to authenticator;
grant rapidform_admin    to authenticator;

grant usage                     on schema public to postgres, anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to postgres, anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to postgres, anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to postgres, anon, authenticated, service_role;

-- Allow Extensions to be used in the API
grant usage                     on schema extensions to postgres, anon, authenticated, service_role;

-- Set up namespacing
alter user rapidform_admin SET search_path TO public, extensions; -- don't include the "auth" schema

-- These are required so that the users receive grants whenever "rapidform_admin" creates tables/function
alter default privileges for user rapidform_admin in schema public grant all
    on sequences to postgres, anon, authenticated, service_role;
alter default privileges for user rapidform_admin in schema public grant all
    on tables to postgres, anon, authenticated, service_role;
alter default privileges for user rapidform_admin in schema public grant all
    on functions to postgres, anon, authenticated, service_role;

-- Set short statement/query timeouts for API roles
alter role anon set statement_timeout = '3s';
alter role authenticated set statement_timeout = '8s';


---------------------------------- 01-auth-schema ----------------------------------
CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION rapidform_admin;

-- auth.users definition

CREATE TABLE auth.users (
	instance_id uuid NULL,
	id uuid NOT NULL UNIQUE,
	aud varchar(255) NULL,
	"role" varchar(255) NULL,
	email varchar(255) NULL UNIQUE,
	encrypted_password varchar(255) NULL,
	confirmed_at timestamptz NULL,
	invited_at timestamptz NULL,
	confirmation_token varchar(255) NULL,
	confirmation_sent_at timestamptz NULL,
	recovery_token varchar(255) NULL,
	recovery_sent_at timestamptz NULL,
	email_change_token varchar(255) NULL,
	email_change varchar(255) NULL,
	email_change_sent_at timestamptz NULL,
	last_sign_in_at timestamptz NULL,
	raw_app_meta_data jsonb NULL,
	raw_user_meta_data jsonb NULL,
	is_super_admin bool NULL,
	created_at timestamptz NULL,
	updated_at timestamptz NULL,
	CONSTRAINT users_pkey PRIMARY KEY (id)
);
CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, email);
CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);
comment on table auth.users is 'Auth: Stores user login data within a secure schema.';

-- auth.refresh_tokens definition

CREATE TABLE auth.refresh_tokens (
	instance_id uuid NULL,
	id bigserial NOT NULL,
	"token" varchar(255) NULL,
	user_id varchar(255) NULL,
	revoked bool NULL,
	created_at timestamptz NULL,
	updated_at timestamptz NULL,
	CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id)
);
CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);
CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);
CREATE INDEX refresh_tokens_token_idx ON auth.refresh_tokens USING btree (token);
comment on table auth.refresh_tokens is 'Auth: Store of tokens used to refresh JWT tokens once they expire.';

-- auth.instances definition

CREATE TABLE auth.instances (
	id uuid NOT NULL,
	uuid uuid NULL,
	raw_base_config text NULL,
	created_at timestamptz NULL,
	updated_at timestamptz NULL,
	CONSTRAINT instances_pkey PRIMARY KEY (id)
);
comment on table auth.instances is 'Auth: Manages users across multiple sites.';

-- auth.audit_log_entries definition

CREATE TABLE auth.audit_log_entries (
	instance_id uuid NULL,
	id uuid NOT NULL,
	payload json NULL,
	created_at timestamptz NULL,
	CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id)
);
CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);
comment on table auth.audit_log_entries is 'Auth: Audit trail for user actions.';

-- auth.schema_migrations definition

CREATE TABLE auth.schema_migrations (
	"version" varchar(255) NOT NULL,
	CONSTRAINT schema_migrations_pkey PRIMARY KEY ("version")
);
comment on table auth.schema_migrations is 'Auth: Manages updates to the auth system.';

-- INSERT INTO auth.schema_migrations (version)
-- VALUES  ('20171026211738'),
--         ('20171026211808'),
--         ('20171026211834'),
--         ('20180103212743'),
--         ('20180108183307'),
--         ('20180119214651'),
--         ('20180125194653');

create or replace function auth.uid()
returns uuid
language sql stable
as $$
  select
  	coalesce(
		current_setting('request.jwt.claim.sub', true),
		(current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
	)::uuid
$$;

create or replace function auth.role()
returns text
language sql stable
as $$
  select
  	coalesce(
		current_setting('request.jwt.claim.role', true),
		(current_setting('request.jwt.claims', true)::jsonb ->> 'role')
	)::text
$$;

create or replace function auth.email()
returns text
language sql stable
as $$
  select
  	coalesce(
		current_setting('request.jwt.claim.email', true),
		(current_setting('request.jwt.claims', true)::jsonb ->> 'email')
	)::text
$$;

-- usage on auth functions to API roles
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;

-- rapidform super admin
CREATE USER rapidform_auth_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
GRANT ALL PRIVILEGES ON SCHEMA auth TO rapidform_auth_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO rapidform_auth_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO rapidform_auth_admin;
ALTER USER rapidform_auth_admin SET search_path = "auth";
ALTER table "auth".users OWNER TO rapidform_auth_admin;
ALTER table "auth".refresh_tokens OWNER TO rapidform_auth_admin;
ALTER table "auth".audit_log_entries OWNER TO rapidform_auth_admin;
ALTER table "auth".instances OWNER TO rapidform_auth_admin;
ALTER table "auth".schema_migrations OWNER TO rapidform_auth_admin;

ALTER FUNCTION "auth"."uid" OWNER TO rapidform_auth_admin;
ALTER FUNCTION "auth"."role" OWNER TO rapidform_auth_admin;
ALTER FUNCTION "auth"."email" OWNER TO rapidform_auth_admin;
GRANT EXECUTE ON FUNCTION "auth"."uid"() TO PUBLIC;
GRANT EXECUTE ON FUNCTION "auth"."role"() TO PUBLIC;
GRANT EXECUTE ON FUNCTION "auth"."email"() TO PUBLIC;


---------------------------------- 02-accounts-schema ----------------------------------
CREATE SCHEMA IF NOT EXISTS accounts AUTHORIZATION rapidform_admin;

-- define the account data
CREATE TABLE accounts.account (
    id uuid NOT NULL UNIQUE,
    alias varchar(255) NULL,
    url_alias varchar(255) NULL,
    stripe_customer_id varchar(255) NULL,
    custom_domain varchar(255) NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL
);

COMMENT ON TABLE accounts.account IS 'Accounts: Stores account data.';

-- define members and permissions to the account
CREATE TABLE accounts.member (
    account_id uuid NOT NULL,
    user_id uuid NOT NULL,
    "role" integer NOT NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    CONSTRAINT member_pkey PRIMARY KEY (account_id, user_id),
    CONSTRAINT member_account_id_fkey FOREIGN KEY (account_id)
        REFERENCES accounts.account (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
    -- ## Should be enabled. However, Prisma doesn't support
    -- ## Follow - https://github.com/prisma/prisma/issues/1175
    -- CONSTRAINT member_user_id_fkey FOREIGN KEY (user_id)
    --     REFERENCES auth.users (id) MATCH SIMPLE
    --     ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX accounts_member_account_id ON accounts.member USING btree (account_id);
COMMENT ON TABLE accounts.member IS 'Accounts: Stores members of accounts.';

-- usage on auth functions to API roles
GRANT USAGE ON SCHEMA accounts TO anon, authenticated, service_role;

-- rapidform super admin
CREATE USER rapidform_account_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
GRANT ALL PRIVILEGES ON SCHEMA accounts TO rapidform_account_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA accounts TO rapidform_account_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA accounts TO rapidform_account_admin;
ALTER USER rapidform_account_admin SET search_path = "accounts";
ALTER table "accounts".account OWNER TO rapidform_account_admin;
ALTER table "accounts".member OWNER TO rapidform_account_admin;


---------------------------------- 03-forms-schema ----------------------------------
CREATE SCHEMA IF NOT EXISTS forms AUTHORIZATION rapidform_admin;

-- define the form metadata
CREATE TABLE forms.metadata (
    id uuid NOT NULL UNIQUE,
    account_id uuid NOT NULL,
    title varchar(255) NULL,
    form_type varchar(255) NULL,
    locale varchar(255) NULL,
    is_public bool NULL,
    show_rapidform_branding bool NULL,
    show_number_of_submissions bool NULL,
    show_cookie_consent bool NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    CONSTRAINT metadata_pkey PRIMARY KEY (id)
);

CREATE INDEX forms_account_id_metadata_type ON forms.metadata USING btree (account_id, form_type);
CREATE INDEX forms_account_id ON forms.metadata USING btree (account_id);
COMMENT ON TABLE forms.metadata IS 'Forms: Stores metadata for forms.';

-- define the form fields
CREATE TABLE forms.field (
    id uuid NOT NULL UNIQUE,
    metadata_id uuid NOT NULL,
    title varchar(255) NULL,
    order_index integer NULL,
    "type" varchar(255) NULL,
    "required" bool NULL,
    image_path varchar(255) NULL,
    options jsonb NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    CONSTRAINT fields_pkey PRIMARY KEY (id),
    CONSTRAINT field_metadata_id_fkey FOREIGN KEY (metadata_id)
        REFERENCES forms.metadata (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX forms_field_metadata_id ON forms.field USING btree (metadata_id);
COMMENT ON TABLE forms.field IS 'Forms: Stores fields for forms.';

-- define the form submission session
CREATE TABLE forms.session (
    id uuid NOT NULL UNIQUE,
    metadata_id uuid NOT NULL,
    ip_address varchar(255) NULL,
    user_agent varchar(255) NULL,
    completed bool NULL,
    created_at timestamptz NULL,
    ended_at timestamptz NULL,
    CONSTRAINT session_pkey PRIMARY KEY (id),
    CONSTRAINT session_metadata_id_fkey FOREIGN KEY (metadata_id)
        REFERENCES forms.metadata (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX forms_session_metadata_id ON forms.session USING btree (metadata_id);
CREATE INDEX forms_session_user_agent ON forms.session USING btree (user_agent);
COMMENT ON TABLE forms.session IS 'Forms: Stores sessions for forms.';

-- define the form submissions
CREATE TABLE forms.submission (
    id uuid NOT NULL UNIQUE,
    metadata_id uuid NOT NULL,
    "session_id" uuid NOT NULL,
    field_id uuid NOT NULL,
    value jsonb NULL,
    submited_at timestamptz NULL,
    CONSTRAINT submission_pkey PRIMARY KEY (id),
    CONSTRAINT submission_metadata_id_fkey FOREIGN KEY (metadata_id)
        REFERENCES forms.metadata (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT field_id_fkey FOREIGN KEY (field_id)
        REFERENCES forms.field (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT session_id_fkey FOREIGN KEY (session_id)
        REFERENCES forms.session (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX forms_submission_metadata_id ON forms.submission USING btree (metadata_id);
CREATE INDEX forms_submission_session_metadata_id ON forms.submission USING btree (metadata_id, session_id);
CREATE INDEX forms_submission_session_id ON forms.submission USING btree (session_id);
COMMENT ON TABLE forms.submission IS 'Forms: Stores submissions for forms.';

-- define the form flow rules
CREATE TABLE forms.flow_rules (
    id uuid NOT NULL UNIQUE,
    metadata_id uuid NOT NULL,
    field_id uuid NOT NULL,
    condition varchar(255) NULL,
    value jsonb NULL,
    next_field_id uuid NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    CONSTRAINT flow_rules_pkey PRIMARY KEY (id),
    CONSTRAINT flow_rules_metadata_id_fkey FOREIGN KEY (metadata_id)
        REFERENCES forms.metadata (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT field_id_fkey FOREIGN KEY (field_id)
        REFERENCES forms.field (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT next_field_id_fkey FOREIGN KEY (next_field_id)
        REFERENCES forms.field (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX forms_flow_rules_metadata_id ON forms.flow_rules USING btree (metadata_id);
CREATE INDEX forms_flow_rules_field_id ON forms.flow_rules USING btree (field_id);
COMMENT ON TABLE forms.flow_rules IS 'Forms: Stores flow rules for forms.';

-- define the webhook/integration for the form
CREATE TABLE forms.connection (
    id uuid NOT NULL UNIQUE,
    metadata_id uuid NOT NULL,
    type varchar(255) NULL,
    options jsonb NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    CONSTRAINT connection_pkey PRIMARY KEY (id),
    CONSTRAINT connection_metadata_id_fkey FOREIGN KEY (metadata_id)
        REFERENCES forms.metadata (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX forms_connection_metadata_id ON forms.connection USING btree (metadata_id);
CREATE INDEX forms_connection_type ON forms.connection USING btree (type);
COMMENT ON TABLE forms.connection IS 'Forms: Stores connections for forms.';

-- usage on auth functions to API roles
GRANT USAGE ON SCHEMA forms TO anon, authenticated, service_role;

-- rapidform super admin
CREATE USER rapidform_forms_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
GRANT ALL PRIVILEGES ON SCHEMA forms TO rapidform_forms_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA forms TO rapidform_forms_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA forms TO rapidform_forms_admin;
ALTER USER rapidform_forms_admin SET search_path = "forms";
ALTER table "forms".metadata OWNER TO rapidform_forms_admin;
ALTER table "forms".field OWNER TO rapidform_forms_admin;
ALTER table "forms".session OWNER TO rapidform_forms_admin;
ALTER table "forms".submission OWNER TO rapidform_forms_admin;
ALTER table "forms".flow_rules OWNER TO rapidform_forms_admin;
ALTER table "forms".connection OWNER TO rapidform_forms_admin;


---------------------------------- 04-templates-schema ----------------------------------
CREATE SCHEMA IF NOT EXISTS templates AUTHORIZATION rapidform_admin;

-- define the template
CREATE TABLE templates.template (
    "name" varchar(255) NOT NULL UNIQUE,
    "description" varchar(255) NULL,
    publisher varchar(255) NULL,
    "version" varchar(255) NULL,
    account_id uuid NULL,
    CONSTRAINT template_pkey PRIMARY KEY ("name")
);

CREATE INDEX templates_account_id ON templates.template USING btree (account_id);
COMMENT ON TABLE templates.template IS 'Templates: Stores templates.';

-- define the template metadata
CREATE TABLE templates.metadata (
    id uuid NOT NULL UNIQUE,
    template_name varchar(255) NOT NULL,
    title varchar(255) NULL,
    form_type varchar(255) NULL,
    locale varchar(255) NULL,
    CONSTRAINT metadata_pkey PRIMARY KEY (id, template_name),
    CONSTRAINT metadata_template_name_fkey FOREIGN KEY (template_name)
        REFERENCES templates.template ("name") MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX templates_metadata_template_name ON templates.metadata USING btree (template_name);
COMMENT ON TABLE templates.metadata IS 'Templates: Stores metadata for templates.';

-- define the template fields
CREATE TABLE templates.field (
    id uuid NOT NULL UNIQUE,
    metadata_id uuid NOT NULL,
    title varchar(255) NULL,
    order_index integer NULL,
    "type" varchar(255) NULL,
    "required" bool NULL,
    image_path varchar(255) NULL,
    options jsonb NULL,
    CONSTRAINT fields_pkey PRIMARY KEY (id, metadata_id),
    CONSTRAINT field_metadata_id_fkey FOREIGN KEY (metadata_id)
        REFERENCES templates.metadata (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX templates_field_metadata_id ON templates.field USING btree (metadata_id);
COMMENT ON TABLE templates.field IS 'Templates: Stores fields for templates.';

-- define the template flow rules
CREATE TABLE templates.flow_rule (
    id uuid NOT NULL UNIQUE,
    metadata_id uuid NOT NULL,
    field_id uuid NOT NULL,
    condition varchar(255) NULL,
    value jsonb NULL,
    next_field_id uuid NULL,
    CONSTRAINT flow_rule_pkey PRIMARY KEY (id, metadata_id),
    CONSTRAINT flow_rule_metadata_id_fkey FOREIGN KEY (metadata_id)
        REFERENCES templates.metadata (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT flow_rule_field_id_fkey FOREIGN KEY (field_id)
        REFERENCES templates.field (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT flow_rule_next_field_id_fkey FOREIGN KEY (next_field_id)
        REFERENCES templates.field (id) MATCH SIMPLE
        ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX templates_flow_rule_metadata_id ON templates.flow_rule USING btree (metadata_id);
CREATE INDEX templates_flow_rule_field_id ON templates.flow_rule USING btree (field_id);
CREATE INDEX templates_flow_rule_next_field_id ON templates.flow_rule USING btree (next_field_id);
COMMENT ON TABLE templates.flow_rule IS 'Templates: Stores flow rules for templates.';

CREATE TABLE templates.connection (
    "name" varchar(255) NOT NULL UNIQUE,
    icon varchar(255) NULL,
    publisher varchar(255) NULL,
    "description" varchar(255) NULL,
    "type" varchar(255) NOT NULL,
    inputs jsonb[] NULL,
    CONSTRAINT connection_pkey PRIMARY KEY (name)
);

CREATE INDEX templates_connection_type ON templates.connection USING btree (type);
COMMENT ON TABLE templates.connection IS 'Templates: Stores connections for templates.';

-- usage on auth functions to API roles
GRANT USAGE ON SCHEMA templates TO anon, authenticated, service_role;

-- rapidform super admin
CREATE USER rapidform_templates_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
GRANT ALL PRIVILEGES ON SCHEMA templates TO rapidform_templates_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA templates TO rapidform_templates_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA templates TO rapidform_templates_admin;
ALTER USER rapidform_templates_admin SET search_path = "templates";
ALTER table templates.template OWNER TO rapidform_templates_admin;
ALTER table templates.metadata OWNER TO rapidform_templates_admin;
ALTER table templates.field OWNER TO rapidform_templates_admin;
ALTER table templates.flow_rule OWNER TO rapidform_templates_admin;
ALTER table templates.connection OWNER TO rapidform_templates_admin;


