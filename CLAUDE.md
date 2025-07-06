# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup and Installation
```bash
pnpm install          # Install dependencies
```

### Development
```bash
pnpm dev              # Start development server (port 3010)
pnpm dev:desktop      # Start desktop development server (port 3015)
```

### Build and Production
```bash
pnpm build            # Build the application
pnpm build:analyze    # Build with bundle analysis
pnpm build:docker     # Build for Docker
pnpm build:electron   # Build for Electron desktop app
pnpm start            # Start production server (port 3210)
```

### Testing
```bash
pnpm test             # Run all tests (app + server)
pnpm test-app         # Run client-side tests
pnpm test-server      # Run server-side tests
pnpm test:update      # Update test snapshots
pnpm test-app:coverage     # Run app tests with coverage
pnpm test-server:coverage  # Run server tests with coverage
```

### Code Quality
```bash
pnpm lint             # Run all linting (TypeScript, style, type-check, circular deps)
pnpm lint:ts          # Lint TypeScript files with ESLint
pnpm lint:style       # Lint styles with stylelint
pnpm type-check       # TypeScript type checking with tsgo
pnpm lint:circular    # Check for circular dependencies
pnpm prettier         # Format all files with Prettier
```

### Database
```bash
pnpm db:generate      # Generate database schema and client
pnpm db:migrate       # Run database migrations
pnpm db:push          # Push schema to database
pnpm db:studio        # Open Drizzle Studio (database GUI)
```

### Internationalization
```bash
pnpm i18n             # Generate internationalization files
```

## Project Architecture

### High-Level Structure
This is **Lobe Chat**, a modern AI chatbot framework built with Next.js 15, supporting multiple AI providers, plugins, and both local/remote databases.

### Key Technologies
- **Frontend**: Next.js 15 with React 19, Ant Design, Zustand state management
- **Backend**: tRPC for type-safe APIs, Drizzle ORM for database
- **Database**: PostgreSQL (server) or PGLite (client-side)
- **AI Integration**: Multiple providers via unified runtime interface
- **Testing**: Vitest for unit tests, separate client/server test configs
- **Deployment**: Vercel, Docker, or self-hosted options

### Core Directory Structure

#### `/src/app` - Next.js App Router
- `(backend)/` - Server-side API routes and middleware
- `[variants]/` - Main application layouts with parallel routes
- App-level configuration (manifest, sitemap, robots)

#### `/src/store` - Zustand State Management
- Modular stores for different features (agent, chat, session, user, etc.)
- Type-safe selectors and actions
- Middleware for devtools integration

#### `/src/services` - Business Logic Layer
- Client/server service implementations
- Unified API interfaces for different features
- Separation between client-side and server-side logic

#### `/src/database` - Database Layer
- Drizzle ORM schemas and models
- Migration files and database utilities
- Client-side (PGLite) and server-side (PostgreSQL) implementations

#### `/src/features` - React Components and UI Features
- Modular feature components (AgentSetting, ChatInput, etc.)
- Reusable UI components and hooks

#### `/src/libs` - External Integrations
- Model runtime abstractions for AI providers
- Authentication integrations (NextAuth, Clerk)
- External service wrappers (MCP, traces, etc.)

### Key Architectural Patterns

#### AI Provider Integration
The system uses a unified `ModelRuntime` interface to support 40+ AI providers (OpenAI, Anthropic, Google, etc.). Each provider is configured in `/src/config/modelProviders/`.

#### Database Abstraction
Supports both local (PGLite in browser) and remote (PostgreSQL) databases through a unified interface. Schemas are defined in `/src/database/schemas/`.

#### Plugin System
Extensible plugin architecture for function calling and custom tools. Plugins are managed through the `/src/tools/` directory.

#### Internationalization
Full i18n support with 20+ languages. Locale files are in `/locales/` and generated through automated workflows.

#### State Management
Uses Zustand with a modular approach. Each feature has its own store with selectors for derived state.

### Development Workflow

1. **Local Development**: Use `pnpm dev` to start the development server
2. **Database Setup**: Run `pnpm db:migrate` to set up the database schema
3. **Testing**: Both client and server tests are separated (`test-app` vs `test-server`)
4. **Type Safety**: The project uses strict TypeScript with `tsgo` for validation
5. **Code Quality**: Comprehensive linting setup with ESLint, stylelint, and Prettier

### Important Notes

- The project uses pnpm workspaces with packages in `/packages/`
- Desktop app support via Electron (build with `pnpm build:electron`)
- Docker deployment support with optimized builds
- Extensive testing infrastructure with Vitest and coverage reporting
- Automated workflows for i18n, documentation, and releases

---

## Best Practices & Development Guidelines | Boas Práticas e Diretrizes de Desenvolvimento

### 🏗️ Backend Architecture | Arquitetura Backend

**EN**: The project follows a layered architecture with clear separation of concerns:

**PT-BR**: O projeto segue uma arquitetura em camadas com clara separação de responsabilidades:

#### Data Flow | Fluxo de Dados

**Browser/PWA Mode:**
```
UI (React) → Zustand action → Client Service → Model Layer → PGLite (local DB)
```

**Server Mode:**
```
UI (React) → Zustand action → Client Service → tRPC Client → tRPC Routers → Repositories/Models → Remote PostgreSQL
```

**Electron Desktop Mode:**
```
UI (Renderer) → Zustand action → Client Service → tRPC Client → Local Node.js Service → tRPC Routers → Repositories/Models → PGLite/Remote PostgreSQL
```

#### Key Layers | Camadas Principais

**EN**:
- **Client Services** (`/src/services`): Business logic with environment adaptation (local vs remote)
- **tRPC API Layer** (`/src/server/routers`): Type-safe API endpoints organized by runtime environment
- **Repository Layer** (`/src/database/repositories`): Complex cross-table queries and data aggregation
- **Model Layer** (`/src/database/models`): Basic CRUD operations for individual tables
- **Database Layer**: PGLite (client-side) or PostgreSQL (server-side)

**PT-BR**:
- **Serviços Cliente** (`/src/services`): Lógica de negócio com adaptação de ambiente (local vs remoto)
- **Camada API tRPC** (`/src/server/routers`): Endpoints de API type-safe organizados por ambiente de execução
- **Camada Repository** (`/src/database/repositories`): Consultas complexas entre tabelas e agregação de dados
- **Camada Model** (`/src/database/models`): Operações CRUD básicas para tabelas individuais
- **Camada Database**: PGLite (client-side) ou PostgreSQL (server-side)

### 🧪 Testing Guidelines | Diretrizes de Teste

#### Test Environments | Ambientes de Teste

**EN**: The project uses two separate test configurations:
- **Client tests** (`vitest.config.ts`): Happy DOM environment, PGLite database
- **Server tests** (`vitest.config.server.ts`): Node.js environment, real PostgreSQL

**PT-BR**: O projeto usa duas configurações de teste separadas:
- **Testes cliente** (`vitest.config.ts`): Ambiente Happy DOM, banco PGLite
- **Testes servidor** (`vitest.config.server.ts`): Ambiente Node.js, PostgreSQL real

#### Running Tests | Executando Testes

```bash
# Correct way | Forma correta
npx vitest run --config vitest.config.ts              # Client tests
npx vitest run --config vitest.config.server.ts       # Server tests
npx vitest run --config vitest.config.ts filename.test.ts -t "specific test"

# Avoid | Evitar
pnpm test some-file    # ❌ Invalid command
vitest test-file.test.ts    # ❌ Enters watch mode
```

#### Security Testing (Database Models) | Testes de Segurança (Models de Banco)

**EN**: **All database model operations MUST include user permission checks:**

**PT-BR**: **Todas as operações de model de banco DEVEM incluir verificações de permissão do usuário:**

```typescript
// ✅ Secure implementation | Implementação segura
update = async (id: string, data: Partial<MyModel>) => {
    return this.db
        .update(myTable)
        .set(data)
        .where(
            and(
                eq(myTable.id, id),
                eq(myTable.userId, this.userId) // ✅ User permission check
            )
        )
        .returning();
};

// ❌ Security vulnerability | Vulnerabilidade de segurança
update = async (id: string, data: Partial<MyModel>) => {
    return this.db
        .update(myTable)
        .set(data)
        .where(eq(myTable.id, id)) // ❌ Missing user check
        .returning();
};
```

### 🎨 Component Development | Desenvolvimento de Componentes

#### Technology Stack | Stack Tecnológico

**EN**: 
- **Styling**: antd-style for complex styles, inline styles for simple cases
- **Layout**: react-layout-kit's Flexbox and Center components
- **Component Priority**: src/components → installed packages → @lobehub/ui → antd

**PT-BR**:
- **Estilização**: antd-style para estilos complexos, estilos inline para casos simples
- **Layout**: componentes Flexbox e Center do react-layout-kit
- **Prioridade de Componentes**: src/components → pacotes instalados → @lobehub/ui → antd

#### Theme System Usage | Uso do Sistema de Tema

```tsx
// Using useTheme hook | Usando hook useTheme
import { useTheme } from 'antd-style';

const MyComponent = () => {
  const theme = useTheme();
  
  return (
    <div style={{ 
      color: theme.colorPrimary,
      backgroundColor: theme.colorBgContainer,
      padding: theme.padding,
      borderRadius: theme.borderRadius
    }}>
      Themed component | Componente com tema
    </div>
  );
}

// Using createStyles | Usando createStyles
const useStyles = createStyles(({ css, token }) => ({
  container: css`
    background-color: ${token.colorBgContainer};
    border-radius: ${token.borderRadius}px;
    padding: ${token.padding}px;
  `,
}));
```

### 🔧 TypeScript Best Practices | Melhores Práticas TypeScript

**EN**:
- Avoid explicit type annotations when TypeScript can infer types
- Use the most accurate type possible (`Record<PropertyKey, unknown>` vs `object`)
- Prefer `interface` over `type` for React component props
- Use `as const satisfies XyzInterface` instead of plain `as const`
- Import index.ts modules like `@/db/index` instead of `@/db`

**PT-BR**:
- Evite anotações de tipo explícitas quando TypeScript pode inferir tipos
- Use o tipo mais preciso possível (`Record<PropertyKey, unknown>` vs `object`)
- Prefira `interface` em vez de `type` para props de componentes React
- Use `as const satisfies XyzInterface` em vez de `as const` simples
- Importe módulos index.ts como `@/db/index` em vez de `@/db`

### 🗃️ Database Model Guidelines | Diretrizes de Models de Banco

**EN**: When creating new database models:

1. **Reference template**: Use `src/database/models/_template.ts` as starting point
2. **User isolation**: ALWAYS implement user permission checks in operations
3. **Type safety**: Use schema-exported types (`NewXxx`, `XxxItem`)
4. **Foreign keys**: Handle constraints properly (use `null` or create referenced records)
5. **Dual environment testing**: Test in both PGLite and PostgreSQL environments

**PT-BR**: Ao criar novos models de banco:

1. **Referência template**: Use `src/database/models/_template.ts` como ponto de partida
2. **Isolamento de usuário**: SEMPRE implemente verificações de permissão do usuário nas operações
3. **Type safety**: Use tipos exportados do schema (`NewXxx`, `XxxItem`)
4. **Chaves estrangeiras**: Trate constraints adequadamente (use `null` ou crie registros referenciados)
5. **Teste ambiente duplo**: Teste nos ambientes PGLite e PostgreSQL

### 🌐 Internationalization (i18n) | Internacionalização

#### Workflow | Fluxo de Trabalho

**EN**:
1. Add new translation keys to `src/locales/default/[namespace].ts`
2. For development, manually translate `locales/zh-CN/namespace.json`
3. For production, run `npm run i18n` to auto-translate all languages

**PT-BR**:
1. Adicione novas chaves de tradução em `src/locales/default/[namespace].ts`
2. Para desenvolvimento, traduza manualmente `locales/zh-CN/namespace.json`
3. Para produção, execute `npm run i18n` para auto-traduzir todos os idiomas

#### Usage in Components | Uso em Componentes

```tsx
import { useTranslation } from "react-i18next";

const MyComponent = () => {
    const { t } = useTranslation("common");

    return (
        <div>
            <h1>{t("newFeature.title")}</h1>
            <p>{t("newFeature.description")}</p>
            <button>{t("newFeature.button")}</button>
        </div>
    );
};
```

### 🏪 State Management (Zustand) | Gerenciamento de Estado

#### Slice Organization | Organização de Slices

**EN**: Each store uses modular slice architecture:

**PT-BR**: Cada store usa arquitetura de slice modular:

```
src/store/[storeName]/
├── slices/
│   └── [sliceName]/
│       ├── action.ts           # Actions definition
│       ├── initialState.ts     # State structure and initial values
│       ├── selectors.ts        # State selectors
│       └── index.ts           # Module exports
├── initialState.ts            # Aggregated initial state
├── store.ts                   # Store definition and setup
└── selectors.ts              # Unified selectors export
```

#### Selector Pattern | Padrão de Seletores

```typescript
// In slice selectors.ts | Em seletores do slice
const currentTopics = (s: ChatStoreState): ChatTopic[] => s.topicMaps[s.activeId];
const getTopicById = (id: string) => (s: ChatStoreState): ChatTopic | undefined =>
  currentTopics(s)?.find((topic) => topic.id === id);

// Export as unified object | Exporte como objeto unificado
export const topicSelectors = {
  currentTopics,
  getTopicById,
  // ... other selectors
};
```

### 📁 Code Organization | Organização de Código

**EN**:
- **Keep related tests near source files**: Use co-location pattern (component.test.tsx next to component.tsx)
- **Use meaningful file names**: Prefer descriptive names over generic ones
- **Group by feature**: Organize components and utilities by domain/feature
- **Maintain consistent imports**: Use absolute imports with path aliases

**PT-BR**:
- **Mantenha testes relacionados próximos aos arquivos fonte**: Use padrão de co-localização (component.test.tsx próximo ao component.tsx)
- **Use nomes de arquivo significativos**: Prefira nomes descritivos em vez de genéricos
- **Agrupe por funcionalidade**: Organize componentes e utilitários por domínio/funcionalidade
- **Mantenha imports consistentes**: Use imports absolutos com aliases de caminho

### 🚨 Security Guidelines | Diretrizes de Segurança

**EN**: **Database layer is the first line of security defense. Every user data operation MUST include user permission checks.**

**PT-BR**: **A camada de banco é a primeira linha de defesa de segurança. Toda operação de dados do usuário DEVE incluir verificações de permissão do usuário.**

#### Required Security Tests | Testes de Segurança Obrigatórios

```typescript
it("should not update records of other users", async () => {
    // Create other user's record | Criar registro de outro usuário
    const [otherUserRecord] = await serverDB
        .insert(myTable)
        .values({ userId: "other-user", data: "original" })
        .returning();

    // Try to update other user's record | Tentar atualizar registro de outro usuário
    const result = await myModel.update(otherUserRecord.id, { data: "hacked" });

    // Should return undefined/empty (permission check failed)
    // Deve retornar undefined/vazio (verificação de permissão falhou)
    expect(result).toBeUndefined();

    // Verify original data unchanged | Verificar que dados originais não mudaram
    const unchanged = await serverDB.query.myTable.findFirst({
        where: eq(myTable.id, otherUserRecord.id),
    });
    expect(unchanged?.data).toBe("original");
});
```