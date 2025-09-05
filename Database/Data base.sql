-- Включение расширения для генерации UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Создание пользовательских типов для ограничения значений
CREATE TYPE workspace_role AS ENUM ('owner', 'admin', 'member');
CREATE TYPE task_priority AS ENUM ('low', 'medium', 'high');

-- Функция для автоматического обновления поля updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Таблица пользователей
CREATE TABLE "users" (
  "id" uuid UNIQUE PRIMARY KEY DEFAULT (uuid_generate_v4()),
  "email" varchar(255) UNIQUE NOT NULL,
  "password_hash" varchar(255) NOT NULL,
  "name" varchar(255),
  "avatar_url" text,
  "email_verified" timestamp DEFAULT NULL,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

-- Таблица рабочих пространств
CREATE TABLE "workspaces" (
  "id" uuid PRIMARY KEY DEFAULT (uuid_generate_v4()),
  "name" varchar(255) NOT NULL,
  "description" text,
  "owner_id" uuid NOT NULL,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

-- Таблица участников рабочих пространств
CREATE TABLE "workspace_members" (
  "id" uuid PRIMARY KEY DEFAULT (uuid_generate_v4()),
  "workspace_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "role" workspace_role DEFAULT 'member',
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

-- Таблица проектов
CREATE TABLE "projects" (
  "id" uuid PRIMARY KEY DEFAULT (uuid_generate_v4()),
  "name" varchar(255) NOT NULL,
  "description" text,
  "color" varchar(20),
  "workspace_id" uuid NOT NULL,
  "owner_id" uuid NOT NULL,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

-- Таблица списков задач
CREATE TABLE "task_lists" (
  "id" uuid PRIMARY KEY DEFAULT (uuid_generate_v4()),
  "name" varchar(255) NOT NULL DEFAULT 'To Do',
  "position" int,
  "project_id" uuid NOT NULL,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

-- Таблица задач
CREATE TABLE "tasks" (
  "id" uuid PRIMARY KEY DEFAULT (uuid_generate_v4()),
  "title" varchar(500) NOT NULL,
  "description" text,
  "position" int,
  "due_date" timestamp,
  "priority" task_priority DEFAULT 'medium',
  "task_list_id" uuid NOT NULL,
  "project_id" uuid NOT NULL,
  "creator_id" uuid NOT NULL,
  "assignee_id" uuid,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

-- Таблица вложений задач
CREATE TABLE "task_attachments" (
  "id" uuid PRIMARY KEY DEFAULT (uuid_generate_v4()),
  "task_id" uuid NOT NULL,
  "uploader_id" uuid NOT NULL,
  "file_name" varchar(255) NOT NULL,
  "file_url" text NOT NULL,
  "file_size" int,
  "mime_type" varchar(100),
  "created_at" timestamp DEFAULT (now())
);

-- Таблица страниц
CREATE TABLE "pages" (
  "id" uuid PRIMARY KEY DEFAULT (uuid_generate_v4()),
  "title" varchar(500) NOT NULL,
  "content" jsonb,
  "project_id" uuid NOT NULL,
  "creator_id" uuid NOT NULL,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

-- Таблица ссылок
CREATE TABLE "links" (
  "id" uuid PRIMARY KEY DEFAULT (uuid_generate_v4()),
  "url" text NOT NULL,
  "title" varchar(500),
  "description" text,
  "image_url" text,
  "project_id" uuid NOT NULL,
  "creator_id" uuid NOT NULL,
  "created_at" timestamp DEFAULT (now())
);

-- Таблица комментариев
CREATE TABLE "comments" (
  "id" uuid PRIMARY KEY DEFAULT (uuid_generate_v4()),
  "content" text NOT NULL,
  "task_id" uuid,
  "author_id" uuid NOT NULL,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

-- Таблица тегов
CREATE TABLE "tags" (
  "id" uuid PRIMARY KEY DEFAULT (uuid_generate_v4()),
  "name" varchar(100) NOT NULL,
  "color" varchar(20),
  "project_id" uuid NOT NULL,
  "created_at" timestamp DEFAULT (now())
);

-- Таблица связи задач и тегов (многие-ко-многим)
CREATE TABLE "task_tags" (
  "id" uuid PRIMARY KEY DEFAULT (uuid_generate_v4()),
  "task_id" uuid,
  "tag_id" uuid,
  "created_at" timestamp DEFAULT (now())
);

-- Создание индексов для улучшения производительности
CREATE UNIQUE INDEX "workspace_members_workspace_id_user_id_idx" ON "workspace_members" ("workspace_id", "user_id");
CREATE UNIQUE INDEX "task_tags_task_id_tag_id_idx" ON "task_tags" ("task_id", "tag_id");

-- Индексы для внешних ключей
CREATE INDEX "workspaces_owner_id_idx" ON "workspaces" ("owner_id");
CREATE INDEX "workspace_members_workspace_id_idx" ON "workspace_members" ("workspace_id");
CREATE INDEX "workspace_members_user_id_idx" ON "workspace_members" ("user_id");
CREATE INDEX "projects_workspace_id_idx" ON "projects" ("workspace_id");
CREATE INDEX "projects_owner_id_idx" ON "projects" ("owner_id");
CREATE INDEX "task_lists_project_id_idx" ON "task_lists" ("project_id");
CREATE INDEX "tasks_task_list_id_idx" ON "tasks" ("task_list_id");
CREATE INDEX "tasks_project_id_idx" ON "tasks" ("project_id");
CREATE INDEX "tasks_creator_id_idx" ON "tasks" ("creator_id");
CREATE INDEX "tasks_assignee_id_idx" ON "tasks" ("assignee_id");
CREATE INDEX "tasks_due_date_idx" ON "tasks" ("due_date");
CREATE INDEX "tasks_priority_idx" ON "tasks" ("priority");
CREATE INDEX "task_attachments_task_id_idx" ON "task_attachments" ("task_id");
CREATE INDEX "task_attachments_uploader_id_idx" ON "task_attachments" ("uploader_id");
CREATE INDEX "pages_project_id_idx" ON "pages" ("project_id");
CREATE INDEX "pages_creator_id_idx" ON "pages" ("creator_id");
CREATE INDEX "links_project_id_idx" ON "links" ("project_id");
CREATE INDEX "links_creator_id_idx" ON "links" ("creator_id");
CREATE INDEX "comments_task_id_idx" ON "comments" ("task_id");
CREATE INDEX "comments_author_id_idx" ON "comments" ("author_id");
CREATE INDEX "tags_project_id_idx" ON "tags" ("project_id");
CREATE INDEX "task_tags_task_id_idx" ON "task_tags" ("task_id");
CREATE INDEX "task_tags_tag_id_idx" ON "task_tags" ("tag_id");

-- Добавление внешних ключей с каскадным удалением где это уместно
ALTER TABLE "workspaces" ADD FOREIGN KEY ("owner_id") REFERENCES "users" ("id");

ALTER TABLE "workspace_members" ADD FOREIGN KEY ("workspace_id") REFERENCES "workspaces" ("id") ON DELETE CASCADE;
ALTER TABLE "workspace_members" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "projects" ADD FOREIGN KEY ("workspace_id") REFERENCES "workspaces" ("id") ON DELETE CASCADE;
ALTER TABLE "projects" ADD FOREIGN KEY ("owner_id") REFERENCES "users" ("id");

ALTER TABLE "task_lists" ADD FOREIGN KEY ("project_id") REFERENCES "projects" ("id") ON DELETE CASCADE;

ALTER TABLE "tasks" ADD FOREIGN KEY ("task_list_id") REFERENCES "task_lists" ("id") ON DELETE CASCADE;
ALTER TABLE "tasks" ADD FOREIGN KEY ("project_id") REFERENCES "projects" ("id");
ALTER TABLE "tasks" ADD FOREIGN KEY ("creator_id") REFERENCES "users" ("id");
ALTER TABLE "tasks" ADD FOREIGN KEY ("assignee_id") REFERENCES "users" ("id");

ALTER TABLE "task_attachments" ADD FOREIGN KEY ("task_id") REFERENCES "tasks" ("id") ON DELETE CASCADE;
ALTER TABLE "task_attachments" ADD FOREIGN KEY ("uploader_id") REFERENCES "users" ("id");

ALTER TABLE "pages" ADD FOREIGN KEY ("project_id") REFERENCES "projects" ("id") ON DELETE CASCADE;
ALTER TABLE "pages" ADD FOREIGN KEY ("creator_id") REFERENCES "users" ("id");

ALTER TABLE "links" ADD FOREIGN KEY ("project_id") REFERENCES "projects" ("id") ON DELETE CASCADE;
ALTER TABLE "links" ADD FOREIGN KEY ("creator_id") REFERENCES "users" ("id");

ALTER TABLE "comments" ADD FOREIGN KEY ("task_id") REFERENCES "tasks" ("id") ON DELETE CASCADE;
ALTER TABLE "comments" ADD FOREIGN KEY ("author_id") REFERENCES "users" ("id");

ALTER TABLE "tags" ADD FOREIGN KEY ("project_id") REFERENCES "projects" ("id") ON DELETE CASCADE;

ALTER TABLE "task_tags" ADD FOREIGN KEY ("task_id") REFERENCES "tasks" ("id") ON DELETE CASCADE;
ALTER TABLE "task_tags" ADD FOREIGN KEY ("tag_id") REFERENCES "tags" ("id") ON DELETE CASCADE;

-- Создание триггеров для автоматического обновления updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON "users"
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workspaces_updated_at
    BEFORE UPDATE ON "workspaces"
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workspace_members_updated_at
    BEFORE UPDATE ON "workspace_members"
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at
    BEFORE UPDATE ON "projects"
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_task_lists_updated_at
    BEFORE UPDATE ON "task_lists"
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON "tasks"
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pages_updated_at
    BEFORE UPDATE ON "pages"
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at
    BEFORE UPDATE ON "comments"
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();