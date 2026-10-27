import Link from "next/link";

const tasks = [
  { href: "/admin/contatos", label: "Contatos recebidos" },
  { href: "/admin/acervo", label: "Acervo de equipamentos" },
] as const;

export function AdminNavigation({
  current,
}: {
  current: (typeof tasks)[number]["href"];
}) {
  return (
    <nav
      aria-label="Tarefas prioritárias do banco"
      className="admin-primary-navigation"
    >
      <ul>
        {tasks.map((task) => (
          <li key={task.href}>
            <Link
              aria-current={current === task.href ? "page" : undefined}
              href={task.href}
            >
              {task.label}
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
}
