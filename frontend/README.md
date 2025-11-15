# Production Tracker - Frontend

Next.js 14 frontend for the Production Tracker application.

## Stack

- **Next.js 14** - React framework with App Router
- **TypeScript** - Type-safe JavaScript
- **Tailwind CSS** - Utility-first CSS
- **shadcn/ui** - Component library
- **Zustand** - State management
- **React Hook Form** - Form handling
- **Zod** - Schema validation
- **Wavesurfer.js** - Audio visualization
- **Socket.io** - Real-time communication

## Structure

```
frontend/src/
├── app/              # Next.js app routes
│   ├── layout.tsx    # Root layout
│   ├── page.tsx      # Home page
│   └── globals.css   # Global styles
├── components/
│   └── ui/           # shadcn/ui components
├── hooks/            # Custom React hooks
├── lib/
│   ├── api.ts        # API client
│   └── utils.ts      # Utilities
├── stores/           # Zustand stores
│   └── authStore.ts  # Auth state
└── types/            # TypeScript types
```

## Setup

### Local Development

1. **Install dependencies**
   ```bash
   pnpm install
   ```

2. **Set up environment**
   ```bash
   cp .env.example .env.local
   # Edit .env.local with your configuration
   ```

3. **Start development server**
   ```bash
   pnpm dev
   ```

4. **Open browser**
   Navigate to http://localhost:3000

### Docker

```bash
docker build -f Dockerfile.dev -t production-tracker-frontend .
docker run -p 3000:3000 production-tracker-frontend
```

## Scripts

```bash
# Development server
pnpm dev

# Build for production
pnpm build

# Start production server
pnpm start

# Lint code
pnpm lint

# Format code
pnpm format
```

## Pages

- `/` - Landing page
- `/login` - Login page
- `/register` - Registration page
- `/dashboard` - User dashboard (authenticated)
- `/projects` - Project list (authenticated)
- `/projects/[id]` - Project detail (authenticated)

## State Management

### Zustand Stores

**authStore** (`stores/authStore.ts`)
- User authentication state
- Login/logout actions
- Token management

**projectStore** (to be implemented)
- Current project data
- Real-time updates

**versionStore** (to be implemented)
- Version history
- Comparison state

## API Integration

The API client is configured in `lib/api.ts`:

```typescript
import { apiClient } from '@/lib/api'

// Example usage
const response = await apiClient.get('/api/projects')
const projects = response.data
```

### Authentication

The API client automatically:
- Adds JWT token to requests
- Handles token refresh on 401
- Redirects to login on auth failure

## Components

### UI Components (shadcn/ui)

To add a new component:

```bash
npx shadcn-ui@latest add [component-name]
```

Example:
```bash
npx shadcn-ui@latest add button
npx shadcn-ui@latest add form
```

### Custom Components

Create in `src/components/`:

```typescript
// components/ProjectCard.tsx
export function ProjectCard({ project }) {
  return (
    <div className="rounded-lg border p-4">
      <h3>{project.name}</h3>
      {/* ... */}
    </div>
  )
}
```

## Styling

### Tailwind CSS

Use Tailwind utility classes:

```tsx
<div className="flex items-center justify-between p-4 bg-background">
  <h1 className="text-2xl font-bold">Title</h1>
</div>
```

### Theme

Theme colors are defined in `tailwind.config.ts` and `app/globals.css`.

To customize:
1. Edit CSS variables in `globals.css`
2. Update Tailwind config if needed

## Environment Variables

Required:
- `NEXT_PUBLIC_API_URL` - Backend API URL
- `NEXT_PUBLIC_WS_URL` - WebSocket server URL

Optional:
- `NEXT_PUBLIC_APP_NAME` - App name (default: Production Tracker)
- `NEXT_PUBLIC_MAX_AUDIO_SIZE_MB` - Max upload size (default: 100)

## Development

### Adding a Page

1. Create file in `src/app/`
   ```typescript
   // app/my-page/page.tsx
   export default function MyPage() {
     return <div>My Page</div>
   }
   ```

2. Access at `/my-page`

### Adding a Store

1. Create in `src/stores/`
   ```typescript
   import { create } from 'zustand'

   interface MyStore {
     count: number
     increment: () => void
   }

   export const useMyStore = create<MyStore>((set) => ({
     count: 0,
     increment: () => set((state) => ({ count: state.count + 1 }))
   }))
   ```

2. Use in components
   ```typescript
   const { count, increment } = useMyStore()
   ```

## Production

### Build

```bash
pnpm build
```

### Deploy

Recommended platforms:
- **Vercel** - Optimal for Next.js
- **Netlify** - Good alternative
- **Docker** - Self-hosted

For Vercel:
1. Connect repository
2. Set environment variables
3. Deploy

## TypeScript

### Strict Mode

This project uses strict TypeScript. Avoid:
- `any` types
- `@ts-ignore` comments
- Type assertions unless necessary

### Type Definitions

Add types in `src/types/`:

```typescript
// types/project.ts
export interface Project {
  id: string
  name: string
  bpm?: number
  // ...
}
```

## Best Practices

1. **Use TypeScript strictly** - No `any` types
2. **Component composition** - Small, focused components
3. **Custom hooks** - Extract reusable logic
4. **Error boundaries** - Handle errors gracefully
5. **Loading states** - Always show loading UI
6. **Accessibility** - Use semantic HTML and ARIA labels

## Troubleshooting

### Module not found

```bash
rm -rf node_modules .next
pnpm install
```

### Type errors

```bash
pnpm tsc --noEmit
```

### Linting errors

```bash
pnpm lint --fix
```
