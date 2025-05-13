# 🛠️ Packer + Yandex Cloud: Jenkins CI/CD Web Server

Шаблон образа виртуальной машины для Yandex Cloud с предустановленным Jenkins, CI/CD пайплайном на основе GitHub push. Проект использует Packer для создания кастомного образа на базе Ubuntu, а также Shell- и Groovy-скрипты для установки и конфигурации Jenkins.

---

## 📦 Возможности

- ✅ Автоматическая установка и настройка Jenkins
- ✅ Jenkins запускается с базовой авторизацией (admin/admin123) из .env
- ✅ Автоустановка и настройка Jenkins CLI
- ✅ Автоустановка плагинов для работы с Docker и Git
- ✅ Готов к работе с GitHub webhook для запуска сборок по push
- ✅ Автоматическое создание Jenkins job для сборки и деплоя Docker-контейнера 

---

## 📁 Структура проекта

- web-server.pkr.hcl             # Packer конфигурация
- default.auto.pkrvars.hcl       # Значения переменных по умолчанию
- scripts/
    - update_apt.sh              # Обновление системы и APT
    - setup.sh                   # Основной setup-скрипт
- resources/
    - .env                       # Переменные окружения Jenkins
    - jenkins_job_config.xml     # Конфигурация Jenkins job
- README.md                      # Вы здесь

---

## 🚀 Быстрый старт

### 1. Установите зависимости

- [Packer](https://yandex.cloud/ru/docs/tutorials/infrastructure-management/packer-quickstart)
- [Yandex CLI](https://yandex.cloud/ru/docs/cli/quickstart#install)

### 2. Настройте переменные

Отредактируйте файл `default.auto.pkrvars.hcl`, указав:

- `YC_FOLDER_ID`
- `YC_SUBNET_ID`
- `YC_TOKEN`  
> (остальные переменные имеют значения по умолчанию и закомментированы, но могут быть использованы на Ваше усмотрение)

! В файле .env нобходимо указать репозиторий node.js проекта

### 3. В корне веб-проекта создайте Dockerfile для запуска проекта на сервере

Код Dockerfile:

```bash
# Используем официальный Nginx образ
FROM nginx:alpine

# Копируем файлы из папки dist (Webpack сборка) в стандартную директорию Nginx
COPY dist/ /usr/share/nginx/html/

# Открываем порт 80
EXPOSE 80

# Запускаем Nginx в фоновом режиме
CMD ["nginx", "-g", "daemon off;"]
```

### 4. Запуск сборки образа

```bash
packer init .
packer packer build -var-file=default.auto.pkrvars.hcl  web-server.pkr.hcl .
```

После успешного выполнения у вас будет доступен образ в Yandex Cloud с полностью готовым Jenkins-сервером.

## 📌 Требования для работы

- Доступ к Yandex Cloud и нужные IAM-права
- Подсеть (subnet) с доступом в интернет (для установки Jenkins и плагинов)
- Публичный GitHub-репозиторий с Node.js проектом

---

## 🔐 Безопасность

- Наиболее чувствительная переменная (`YC_TOKEN`) задекларирована с флагом `sensitive = true`.
- Файл `.env` не должен попадать в VCS. Добавьте `.env` в `.gitignore`.

---

## 🧪 Тестирование

После запуска виртуальной машины на базе созданного образа, проверьте:

1. Доступность Jenkins по `http://<vm-ip>:8080`
2. Возможность логина (`admin` / `admin123`)
3. Что Jenkins job срабатывает после `git push` в ветку `main`

---