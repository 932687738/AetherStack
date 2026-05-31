# AI 模块单元测试模板

> 配合 `openspec/references/ai-tdd-standards.md`；仅用于 L1 AI 核心模块。

## ChatClient 封装层

```java
@ExtendWith(MockitoExtension.class)
class AgentChatServiceTest {

    @InjectMocks
    private AgentChatService agentChatService;

    @Mock
    private ChatClient.Builder chatClientBuilder;
    @Mock
    private ChatClient chatClient;
    @Mock
    private ChatClient.ChatClientRequestSpec requestSpec;
    @Mock
    private ChatClient.StreamResponseSpec streamResponseSpec;
    @Mock
    private ToolRegistry toolRegistry;
    @Mock
    private MessageChatMemoryAdvisor memoryAdvisor;

    @Test
    @DisplayName("TC-REQ1-01 stream_shouldEmitTokensWithoutCallingRealLlm")
    void stream_shouldEmitTokensWithoutCallingRealLlm() {
        when(chatClientBuilder.clone()).thenReturn(chatClientBuilder);
        when(chatClientBuilder.build()).thenReturn(chatClient);
        when(chatClient.prompt()).thenReturn(requestSpec);
        when(requestSpec.advisors(any())).thenReturn(requestSpec);
        when(requestSpec.system(anyString())).thenReturn(requestSpec);
        when(requestSpec.user(anyString())).thenReturn(requestSpec);
        when(requestSpec.tools(any())).thenReturn(requestSpec);
        when(requestSpec.stream()).thenReturn(streamResponseSpec);
        when(streamResponseSpec.content()).thenReturn(Flux.just("hello", " world"));

        ConversationContext context = ConversationContext.builder("cid")
                .attribute(OrchestrationPlan.CONTEXT_KEY, OrchestrationPlan.agentFallback())
                .build();

        StepVerifier.create(agentChatService.stream("sys", "hi", context))
                .expectNext("hello")
                .expectNext(" world")
                .verifyComplete();

        verify(requestSpec).system(argThat(s -> s.contains("编排") || s.length() > 0));
    }
}
```

## Prompt 组装

```java
@Test
@DisplayName("TC-REQ2-01 render_shouldInjectRoutedAgentAndStripPlaceholders")
void render_shouldInjectRoutedAgentAndStripPlaceholders() {
    ConversationContext ctx = ConversationContext.builder("c1")
            .routedAgent("code-generation")
            .build();

    String rendered = promptService.render(
            AgentHubPromptPaths.ORCHESTRATOR_SYSTEM, ctx, "instruction");

    assertThat(rendered).contains("code-generation");
    assertThat(rendered).doesNotContain("{{routedAgent}}");
}
```

## 路由决策（DomainService / Graph prep）

```java
@Test
@DisplayName("TC-REQ3-01 resolveStreamRoute_weatherQuestion_returnsDirectWeather")
void resolveStreamRoute_weatherQuestion_returnsDirectWeather() {
    when(weatherDirectAnswerService.tryDirectAnswer("杭州天气")).thenReturn(Optional.of("晴 25°C"));

    var decision = domainService.resolveStreamRoute(
            "杭州天气", OrchestrationPlan.agentFallback(), Optional.empty());

    assertThat(decision.route()).isEqualTo(AgentChatStreamRoute.DIRECT_WEATHER);
    assertThat(decision.directAnswer()).contains("25");
}
```

## ApplicationService + Mock CompiledGraph

```java
@ExtendWith(MockitoExtension.class)
class AgentChatApplicationServiceTest {

    @InjectMocks
    private AgentChatApplicationService applicationService;

    @Mock
    private CompiledGraph agentChatPrepGraph;
    @Mock
    private AgentChatDomainService domainService;
    @Mock
    private ApplicationEventPublisher events;

    @Test
    @DisplayName("TC-REQ4-01 streamAgentChat_prepGraphThenDirectAnswer")
    void streamAgentChat_prepGraphThenDirectAnswer() {
        Map<String, Object> endMap = prepStateMap(AgentChatStreamRoute.DIRECT_WEATHER, "晴");
        when(agentChatPrepGraph.invoke(any())).thenReturn(Optional.of(mockState(endMap)));

        StepVerifier.create(applicationService.streamAgentChat("cid", "杭州天气"))
                .expectNextMatches(s -> s.startsWith("【路由】"))
                .expectNext("晴")
                .verifyComplete();
    }
}
```

## Flux SSE Controller（WebTestClient）

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureWebTestClient
class AgentHubControllerAiStreamTest {

    @Autowired
    private WebTestClient webTestClient;

    @MockBean
    private AgentChatApplicationService agentChatApplicationService;

    @Test
    void chatAgent_shouldStreamTextEventStream() {
        when(agentChatApplicationService.streamAgentChat(any(), any()))
                .thenReturn(Flux.just("【路由】...\n\n", "answer"));

        webTestClient.post()
                .uri("/api/agent-hub/chat/agent")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(new AgentHubChatRequest("c1", "hi"))
                .exchange()
                .expectStatus().isOk()
                .expectHeader().contentTypeCompatibleWith(MediaType.TEXT_EVENT_STREAM);
    }
}
```

## 命令

```bash
cd D:/cache/workspace/ai
mvn -Dtest=AgentChatDomainServiceTest test
mvn -Dtest=AgentChatApplicationServiceTest test
```

## 禁止项

- 单测依赖 `DASHSCOPE_API_KEY` 或真实 HTTP
- 对完整 prompt 字符串 `assertEquals`
- L1 模块无测试即合并
