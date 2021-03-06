Этот набор скриптов предназначен в первую очередь для облегчения
упаковки, запуска и распространения Windows игр и программ, но может
применяться и в других целях. Скрипты будут работать на всех дистрибутивах
Linux, где установлены стандартные утилиты GNU и оболочка bash.

================== Описание скрипта start.sh ==========================

Настройки скрипта (переменные которые можно изменить), хранятся в файле
settings_start или settings_НАЗВАНИЕСКРИПТА. Там же находится и описание
этих переменных.

Для изменения разрядности префикса на 32-бита, измените значение
переменной WINEARCH на win32 в файле settings_НАЗВАНИЕСКРИПТА

Скрипт можно запустить с параметрами:

	--debug - для включения отладочной информации, полезно
		при проблемах с игрой

Скрипт автоматически использует системный Wine, если рядом с ним
отсутствует каталог wine.

Скрипт активно использует стороние файлы и создает префикс с нуля при
первом запуске, применяя различные настройки из каталога game_info. Скрипт
не предназначем для работы с готовым префиксом.

Скрипт создает каталог documents, в котором будут храниться настройки
и сохранения игр. Удаление префикса в большинстве случаев
не повлияет на сохранения и настройки игр/программ.

Скрипт автоматически пересоздает префикс при изменении имени
пользователя или версии Wine.

Название файла настроек и файла game_info.txt зависит от имени скрипта.
Если скрипт, допустим, называется start-addon.sh он автоматически будет
использовать для настройки файл settings_start-addon и файл
game_info_start-addon.txt, если он есть. Если его нет, будет использоваться
просто game_info.txt. Таким образом можно делать копии скрипта start.sh,
использующие разные настройки и запускающие разные exe файлы.

===================== Описание скрипта tools.sh =======================

Скрипт tools.sh может запускаться с параметрами:

	--cfg - запускает winecfg
	--reg - запускает regedit
	--kill - убивает все запущенные из под текущего префикса процессы Wine
	--fm - запускает файловый менеджер
	--clean - удаляет почти все ненужные файлы из каталога
	--icons - создает на рабочем столе и в меню приложений иконку для
				запуска игры
	--remove-icons - удаляет созданную иконку
	--help - показать доступные параметры

=======================================================================

Описание каталогов и файлов каталога game_info содержится в readme.txt
файлах в каталоге game_info.
