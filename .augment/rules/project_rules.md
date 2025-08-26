---
type: "always_apply"
---

# Dayliz Project Development Guidelines

## Core Architecture Compliance
1. **Follow Established Patterns**: Always adhere to the project's existing architecture patterns including:
   - Clean architecture principles for Flutter frontend and FastAPI backend
   - Database schema patterns (use 'agents' table, implement RLS policies)
   - UI/UX patterns (green color scheme, CustomScrollView + SliverAppBar, etc.)
   - Business logic patterns (zone-based delivery, geofencing, order flow)

## Discovery-First Development
2. **Investigate Before Implementation**: Before writing any new code:
   - Use `codebase-retrieval` to search for existing similar features, components, or utilities
   - Use `git-commit-retrieval` to understand how similar changes were implemented previously
   - Check for reusable systems and components to reduce code duplication
   - Identify if the functionality already exists in a different form that can be extended

## Professional Problem-Solving Process
3. **Senior Developer Approach**: For every task:
   - **Analyze**: Thoroughly understand the user's requirements and context
   - **Research**: Investigate existing codebase patterns and previous implementations
   - **Plan**: Break complex tasks into logical, manageable pieces (20-minute units of work)
   - **Design**: Consider scalability, maintainability, and alignment with business goals
   - **Implement**: Follow established patterns and best practices
   - **Validate**: Suggest testing strategies and verify implementation quality

## Communication & Clarity
4. **Clarification Protocol**: When requirements are ambiguous:
   - Ask specific, targeted questions about unclear aspects
   - Propose your understanding and ask for confirmation
   - Never assume implementation details without validation
   - State your assumptions clearly when proceeding with partial information

## Tool Utilization Strategy
5. **Proactive Tool Usage**: Leverage available MCP servers and tools strategically:
   - Use `codebase-retrieval` for understanding existing code structure
   - Use `git-commit-retrieval` for historical context and patterns
   - Use task management tools for complex multi-step work
   - Use appropriate package managers for dependency management
   - Use browser tools for testing and validation when needed

## Production-Grade Standards
6. **Enterprise-Level Quality**: Maintain standards equivalent to top-tier tech companies:
   - **Security**: Never expose secrets, implement proper RLS policies, follow DPDP Act 2023 compliance
   - **Performance**: Target <200KB initial payload, <3s TTI on 3G networks
   - **Scalability**: Design for growth (local-first cart, zone-based architecture)
   - **Maintainability**: Write clean, documented, testable code
   - **Reliability**: Implement proper error handling, fallback strategies
   - **User Experience**: Follow established UI/UX patterns and accessibility standards
   - **Testing**: Always suggest comprehensive testing strategies for new implementations