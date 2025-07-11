## Set global build ENV
ARG NODEJS_VERSION="22"

## Base image for all building stages
FROM node:${NODEJS_VERSION}-slim AS base

ARG USE_CN_MIRROR

ENV DEBIAN_FRONTEND="noninteractive"

RUN \
    # If you want to build docker in China, build with --build-arg USE_CN_MIRROR=true
    if [ "${USE_CN_MIRROR:-false}" = "true" ]; then \
        sed -i "s/deb.debian.org/mirrors.ustc.edu.cn/g" "/etc/apt/sources.list.d/debian.sources"; \
    fi \
    # Add required package
    && apt update \
    && apt install ca-certificates -qy \
    # Cleanup temp files
    && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

## Builder image, install all the dependencies and build the app
FROM base AS builder

ARG USE_CN_MIRROR
ARG NEXT_PUBLIC_BASE_PATH
ARG NEXT_PUBLIC_SENTRY_DSN
ARG NEXT_PUBLIC_ANALYTICS_POSTHOG
ARG NEXT_PUBLIC_POSTHOG_HOST
ARG NEXT_PUBLIC_POSTHOG_KEY
ARG NEXT_PUBLIC_ANALYTICS_UMAMI
ARG NEXT_PUBLIC_UMAMI_SCRIPT_URL
ARG NEXT_PUBLIC_UMAMI_WEBSITE_ID
ARG FEATURE_FLAGS

ENV NEXT_PUBLIC_BASE_PATH="${NEXT_PUBLIC_BASE_PATH}" \
    FEATURE_FLAGS="${FEATURE_FLAGS}"
# Sentry
ENV NEXT_PUBLIC_SENTRY_DSN="${NEXT_PUBLIC_SENTRY_DSN}" \
    SENTRY_ORG="" \
    SENTRY_PROJECT=""

# Posthog
ENV NEXT_PUBLIC_ANALYTICS_POSTHOG="${NEXT_PUBLIC_ANALYTICS_POSTHOG}" \
    NEXT_PUBLIC_POSTHOG_HOST="${NEXT_PUBLIC_POSTHOG_HOST}" \
    NEXT_PUBLIC_POSTHOG_KEY="${NEXT_PUBLIC_POSTHOG_KEY}"

# Umami
ENV NEXT_PUBLIC_ANALYTICS_UMAMI="${NEXT_PUBLIC_ANALYTICS_UMAMI}" \
    NEXT_PUBLIC_UMAMI_SCRIPT_URL="${NEXT_PUBLIC_UMAMI_SCRIPT_URL}" \
    NEXT_PUBLIC_UMAMI_WEBSITE_ID="${NEXT_PUBLIC_UMAMI_WEBSITE_ID}"

# Node
ENV NODE_OPTIONS="--max-old-space-size=8192"

WORKDIR /app

COPY package.json pnpm-workspace.yaml ./
COPY .npmrc ./
COPY packages ./packages

RUN \
    # If you want to build docker in China, build with --build-arg USE_CN_MIRROR=true
    if [ "${USE_CN_MIRROR:-false}" = "true" ]; then \
        export SENTRYCLI_CDNURL="https://npmmirror.com/mirrors/sentry-cli"; \
        npm config set registry "https://registry.npmmirror.com/"; \
        echo 'canvas_binary_host_mirror=https://npmmirror.com/mirrors/canvas' >> .npmrc; \
    fi \
    # Set the registry for corepack
    && export COREPACK_NPM_REGISTRY=$(npm config get registry | sed 's/\/$//') \
    # Update corepack to latest (nodejs/corepack#612)
    && npm i -g corepack@latest \
    # Enable corepack
    && corepack enable \
    # Use pnpm for corepack
    && corepack use $(sed -n 's/.*"packageManager": "\(.*\)".*/\1/p' package.json) \
    # Install the dependencies
    && pnpm i

COPY . .

# run build standalone for docker version
RUN npm run build:docker

## Production image - simplified approach
FROM node:22-slim

# Create nodejs user
RUN groupadd -g 1001 -r nodejs && useradd -r -g nodejs -u 1001 nextjs

# Copy application files
COPY --from=builder /app/.next/standalone /app/
COPY --from=builder /app/scripts/serverLauncher/startServer.js /app/startServer.js

# Set permissions
RUN chown -R nextjs:nodejs /app

ENV NODE_ENV="production" \
    NODE_OPTIONS="--dns-result-order=ipv4first --use-openssl-ca" \
    NODE_EXTRA_CA_CERTS="" \
    NODE_TLS_REJECT_UNAUTHORIZED="" \
    SSL_CERT_DIR="/etc/ssl/certs/ca-certificates.crt"

# Make the middleware rewrite through local as default
# refs: https://github.com/lobehub/lobe-chat/issues/5876
ENV MIDDLEWARE_REWRITE_THROUGH_LOCAL="1"

# set hostname to localhost
ENV HOSTNAME="0.0.0.0" \
    PORT="3210"

# General Variables
ENV ACCESS_CODE="" \
    API_KEY_SELECT_MODE="" \
    DEFAULT_AGENT_CONFIG="" \
    SYSTEM_AGENT="" \
    FEATURE_FLAGS="" \
    PROXY_URL=""

# Model Variables
ENV \
    # AI21
    AI21_API_KEY="" AI21_MODEL_LIST="" \
    # Ai360
    AI360_API_KEY="" AI360_MODEL_LIST="" \
    # Anthropic
    ANTHROPIC_API_KEY="" ANTHROPIC_MODEL_LIST="" ANTHROPIC_PROXY_URL="" \
    # Amazon Bedrock
    AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY="" AWS_REGION="" AWS_BEDROCK_MODEL_LIST="" \
    # Azure OpenAI
    AZURE_API_KEY="" AZURE_API_VERSION="" AZURE_ENDPOINT="" AZURE_MODEL_LIST="" \
    # Baichuan
    BAICHUAN_API_KEY="" BAICHUAN_MODEL_LIST="" \
    # Cloudflare
    CLOUDFLARE_API_KEY="" CLOUDFLARE_BASE_URL_OR_ACCOUNT_ID="" CLOUDFLARE_MODEL_LIST="" \
    # Cohere
    COHERE_API_KEY="" COHERE_MODEL_LIST="" COHERE_PROXY_URL="" \
    # DeepSeek
    DEEPSEEK_API_KEY="" DEEPSEEK_MODEL_LIST="" \
    # Fireworks AI
    FIREWORKSAI_API_KEY="" FIREWORKSAI_MODEL_LIST="" \
    # Gitee AI
    GITEE_AI_API_KEY="" GITEE_AI_MODEL_LIST="" \
    # GitHub
    GITHUB_TOKEN="" GITHUB_MODEL_LIST="" \
    # Google
    GOOGLE_API_KEY="" GOOGLE_MODEL_LIST="" GOOGLE_PROXY_URL="" \
    # Groq
    GROQ_API_KEY="" GROQ_MODEL_LIST="" GROQ_PROXY_URL="" \
    # Higress
    HIGRESS_API_KEY="" HIGRESS_MODEL_LIST="" HIGRESS_PROXY_URL="" \
    # HuggingFace
    HUGGINGFACE_API_KEY="" HUGGINGFACE_MODEL_LIST="" HUGGINGFACE_PROXY_URL="" \
    # Hunyuan
    HUNYUAN_API_KEY="" HUNYUAN_MODEL_LIST="" \
    # InternLM
    INTERNLM_API_KEY="" INTERNLM_MODEL_LIST="" \
    # Jina
    JINA_API_KEY="" JINA_MODEL_LIST="" JINA_PROXY_URL="" \
    # Minimax
    MINIMAX_API_KEY="" MINIMAX_MODEL_LIST="" \
    # Mistral
    MISTRAL_API_KEY="" MISTRAL_MODEL_LIST="" \
    # ModelScope
    MODELSCOPE_API_KEY="" MODELSCOPE_MODEL_LIST="" MODELSCOPE_PROXY_URL="" \
    # Moonshot
    MOONSHOT_API_KEY="" MOONSHOT_MODEL_LIST="" MOONSHOT_PROXY_URL="" \
    # Novita
    NOVITA_API_KEY="" NOVITA_MODEL_LIST="" \
    # Nvidia NIM
    NVIDIA_API_KEY="" NVIDIA_MODEL_LIST="" NVIDIA_PROXY_URL="" \
    # Ollama
    ENABLED_OLLAMA="" OLLAMA_MODEL_LIST="" OLLAMA_PROXY_URL="" \
    # OpenAI
    OPENAI_API_KEY="" OPENAI_MODEL_LIST="" OPENAI_PROXY_URL="" \
    # OpenRouter
    OPENROUTER_API_KEY="" OPENROUTER_MODEL_LIST="" \
    # Perplexity
    PERPLEXITY_API_KEY="" PERPLEXITY_MODEL_LIST="" PERPLEXITY_PROXY_URL="" \
    # PPIO
    PPIO_API_KEY="" PPIO_MODEL_LIST="" \
    # Qiniu
    QINIU_API_KEY="" QINIU_MODEL_LIST="" QINIU_PROXY_URL="" \
    # Qwen
    QWEN_API_KEY="" QWEN_MODEL_LIST="" QWEN_PROXY_URL="" \
    # SambaNova
    SAMBANOVA_API_KEY="" SAMBANOVA_MODEL_LIST="" \
    # Search1API
    SEARCH1API_API_KEY="" SEARCH1API_MODEL_LIST="" \
    # SenseNova
    SENSENOVA_API_KEY="" SENSENOVA_MODEL_LIST="" \
    # SiliconCloud
    SILICONCLOUD_API_KEY="" SILICONCLOUD_MODEL_LIST="" SILICONCLOUD_PROXY_URL="" \
    # Spark
    SPARK_API_KEY="" SPARK_MODEL_LIST="" SPARK_PROXY_URL="" SPARK_SEARCH_MODE="" \
    # Stepfun
    STEPFUN_API_KEY="" STEPFUN_MODEL_LIST="" \
    # Taichu
    TAICHU_API_KEY="" TAICHU_MODEL_LIST="" \
    # TogetherAI
    TOGETHERAI_API_KEY="" TOGETHERAI_MODEL_LIST="" \
    # Upstage
    UPSTAGE_API_KEY="" UPSTAGE_MODEL_LIST="" \
    # v0 (Vercel)
    V0_API_KEY="" V0_MODEL_LIST="" \
    # vLLM
    VLLM_API_KEY="" VLLM_MODEL_LIST="" VLLM_PROXY_URL="" \
    # Wenxin
    WENXIN_API_KEY="" WENXIN_MODEL_LIST="" \
    # xAI
    XAI_API_KEY="" XAI_MODEL_LIST="" XAI_PROXY_URL="" \
    # Xinference
    XINFERENCE_API_KEY="" XINFERENCE_MODEL_LIST="" XINFERENCE_PROXY_URL="" \
    # 01.AI
    ZEROONE_API_KEY="" ZEROONE_MODEL_LIST="" \
    # Zhipu
    ZHIPU_API_KEY="" ZHIPU_MODEL_LIST="" \
    # Tencent Cloud
    TENCENT_CLOUD_API_KEY="" TENCENT_CLOUD_MODEL_LIST="" \
    # Infini-AI
    INFINIAI_API_KEY="" INFINIAI_MODEL_LIST=""

USER nextjs

EXPOSE 3210/tcp

ENTRYPOINT ["node"]

CMD ["/app/startServer.js"]
