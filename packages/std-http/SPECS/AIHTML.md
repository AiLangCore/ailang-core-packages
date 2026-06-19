# SPEC/AIHTML.md

Status: Draft

## Purpose

AiHTML is AiLang's declarative HTML document and web view language.

AiHTML provides HTML-inspired document composition using AiLang's token-oriented syntax.

AiHTML is:

- Human readable
- AI-friendly
- Deterministic
- Canonically formattable
- Cross-platform
- Safe by default

AiHTML is not:

- Raw HTML
- Razor
- JSX
- React
- Angular Templates
- Browser DOM APIs

AiHTML is intended for:

- Server-side rendering (SSR)
- Static site generation (SSG)
- Email generation
- Reports
- Documentation
- Web applications
- HTTP responses
- Client/server applications

---

# Architecture

AiHTML follows a deterministic Model → Update → View architecture.

```text
Model
  ↓
View (.aihtml)
  ↓
Event
  ↓
Update
  ↓
Model
```

The architecture is intentionally simple, deterministic, and AI-friendly.

---

# File Structure

Views are composed of two files:

```text
Views/
  Home.aihtml
  Home.aihtml.aos
```

The `.aihtml` file owns:

- document structure
- markup
- bindings
- event declarations
- metadata

The `.aihtml.aos` file owns:

- models
- events
- update handlers
- commands
- business logic

Many IDEs automatically group files using this naming convention.

---

# Semantic Authority

AiHTML defines document structure and presentation intent.

AiLang defines meaning.

AiVM executes meaning.

std_http hosts and serves generated documents.

Browser behavior does not define AiHTML semantics.

---

# Routing

Views may declare routes.

Example:

```ailang
Route "/"

Html Home
{
}
```

Route parameters:

```ailang
Route "/weather/:city"

Html Weather
{
}
```

Parameters become available through:

```ailang
route.city
```

Routes may be discovered automatically or registered through a router.

---

# Basic Structure

```ailang
Route "/"

Html Home
{
    Head
    {
        Title model.pageTitle
    }

    Body
    {
        H1 model.title

        P
        {
            Value model.description
        }
    }
}
```

---

# Core Elements

Required v1 elements:

```text
Html

Head
Body

Title
Meta
Link
Script

Header
Footer
Main
Section
Article
Aside
Nav

Div
Span

H1
H2
H3
H4
H5
H6

P

Ul
Ol
Li

Table
Thead
Tbody
Tr
Td
Th

Form
Input
TextArea
Select
Option
Button

Img

A
```

---

# Properties

Properties use token-oriented syntax.

Example:

```ailang
Img hero
{
    Src "/images/logo.png"
    Alt "AiLang Logo"
}
```

---

# Expressions

Any property may contain an AiLang expression.

Literal:

```ailang
Value "Hello"
```

Binding:

```ailang
Value model.title
```

Computed:

```ailang
Value model.firstName ++ " " ++ model.lastName
```

Conditional:

```ailang
Visible model.isLoggedIn
```

Bindings are expressions.

Bindings are not strings.

Invalid:

```ailang
Value "`model.title`"
```

---

# Models

Models are defined in the companion `.aihtml.aos` file.

```ailang
Model HomeModel
{
    pageTitle = "AiLang"
    title = "Welcome"
}
```

---

# Events

Events are defined in AiLang.

```ailang
Event LoginRequested
{
}
```

Usage:

```ailang
Button loginButton
{
    Text "Login"

    OnClick LoginRequested
}
```

---

# Updates

All state mutation occurs through Update handlers.

```ailang
Update LoginRequested
{
    loading = true
}
```

Views never mutate state directly.

---

# Components

AiHTML supports reusable components.

Directory structure:

```text
Views/
  Components/
    UserCard.aihtml
    UserCard.aihtml.aos
```

Component definition:

```ailang
Component UserCard
{
    Props
    {
        userName Text
        email Text
    }

    Html
    {
        Div card
        {
            H3 userName

            P
            {
                Value email
            }
        }
    }
}
```

Usage:

```ailang
Use Components.UserCard

Html Home
{
    UserCard currentUser
    {
        UserName model.user.name
        Email model.user.email
    }
}
```

---

# Component Rules

Components receive data through Props.

Components communicate outward through Events.

Components should avoid hidden mutable state.

All component behavior must remain deterministic.

---

# AI Metadata

AiHTML supports optional non-rendering metadata.

```ailang
Button submit
{
    Role primaryAction

    Intent "Submits the registration form."

    TestId submitButton

    Text "Register"
}
```

Supported metadata:

```text
Role
Intent
TestId
Notes
StateSource
Action
```

Metadata must not affect rendering.

---

# Forms

Forms are declarative.

```ailang
Form registration
{
    Input firstName
    {
        Value model.firstName
    }

    Input lastName
    {
        Value model.lastName
    }

    Button submit
    {
        Text "Register"

        OnClick RegisterUser
    }
}
```

Forms are bound through AiLang expressions.

---

# Server Side Rendering

AiHTML supports deterministic SSR.

```text
AiHTML
  ↓
AiLang Model
  ↓
Canonical HTML
  ↓
HTTP Response
```

SSR output must be deterministic.

---

# Static Site Generation

AiHTML may be pre-rendered.

```text
AiHTML
  ↓
Model
  ↓
Static HTML Files
```

Generated output must be deterministic.

---

# Client / Server Applications

AiHTML may participate in client/server applications hosted through std_http.

```text
Browser
  ↓
std_http
  ↓
AiLang
  ↓
AiHTML
```

Application state remains owned by AiLang.

---

# HTML Compatibility

AiHTML intentionally mirrors common HTML concepts.

```text
Html
Head
Body
Div
Span
Form
Input
Button
Img
A
```

AiHTML is not required to support:

- arbitrary browser DOM mutation
- JavaScript execution
- browser-specific APIs
- CSS framework semantics

---

# Rendering

AiHTML lowers into canonical HTML output.

The same AiHTML source must generate identical HTML for identical inputs.

---

# Validation

Validation must reject:

- duplicate IDs
- unknown properties
- invalid bindings
- unresolved events
- unresolved components
- unsupported HTML features

Validation must be deterministic.

---

# Determinism

For a given:

- AiHTML
- model state
- route
- query parameters
- target profile

AiHTML must produce identical HTML output.

If behavior changes:

1. Update spec.
2. Update goldens.
3. Update implementation.

Never the reverse.

---

# Example

```ailang
Route "/"

Html Home
{
    Head
    {
        Title model.pageTitle
    }

    Body
    {
        Header
        {
            H1 model.title
        }

        Main
        {
            P
            {
                Value model.description
            }

            A docsLink
            {
                Href "/docs"
                Text "Documentation"
            }
        }
    }
}
```

---

# Prime Rule

AiHTML describes document intent.

AiLang owns meaning.

AiVM executes meaning.

std_http hosts and serves the result.