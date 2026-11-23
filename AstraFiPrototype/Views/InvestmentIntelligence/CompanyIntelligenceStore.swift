import Foundation

public struct BusinessSegment: Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let sharePercentage: String?
    public let description: String

    public init(name: String, sharePercentage: String? = nil, description: String) {
        self.name = name
        self.sharePercentage = sharePercentage
        self.description = description
    }
}

public struct VerifiedCompanyProfile: Equatable {
    public let symbol: String
    public let companyName: String
    public let sector: String
    public let industry: String
    public let exchange: String
    public let country: String
    public let whatItDoes: String
    public let operatingSegments: [BusinessSegment]
    public let productsAndPlatforms: [String]
    public let revenueModel: [String]
    public let targetMarkets: [String]
    public let secularGrowthDrivers: [String]
    public let keyBusinessRisks: [String]
    public let keyMetricsToMonitor: [String]
    public let baselineFinancialNotes: [String]

    public init(
        symbol: String,
        companyName: String,
        sector: String,
        industry: String,
        exchange: String,
        country: String,
        whatItDoes: String,
        operatingSegments: [BusinessSegment],
        productsAndPlatforms: [String],
        revenueModel: [String],
        targetMarkets: [String],
        secularGrowthDrivers: [String],
        keyBusinessRisks: [String],
        keyMetricsToMonitor: [String],
        baselineFinancialNotes: [String] = []
    ) {
        self.symbol = symbol
        self.companyName = companyName
        self.sector = sector
        self.industry = industry
        self.exchange = exchange
        self.country = country
        self.whatItDoes = whatItDoes
        self.operatingSegments = operatingSegments
        self.productsAndPlatforms = productsAndPlatforms
        self.revenueModel = revenueModel
        self.targetMarkets = targetMarkets
        self.secularGrowthDrivers = secularGrowthDrivers
        self.keyBusinessRisks = keyBusinessRisks
        self.keyMetricsToMonitor = keyMetricsToMonitor
        self.baselineFinancialNotes = baselineFinancialNotes
    }
}

public final class CompanyIntelligenceStore {
    public static let shared = CompanyIntelligenceStore()

    private let profiles: [String: VerifiedCompanyProfile]

    public init() {
        var store: [String: VerifiedCompanyProfile] = [:]

        // ==========================================
        // 1. TATA CONSULTANCY SERVICES (TCS.NS)
        // ==========================================
        store["TCS.NS"] = VerifiedCompanyProfile(
            symbol: "TCS.NS",
            companyName: "Tata Consultancy Services Ltd",
            sector: "Technology",
            industry: "IT Services & Consulting",
            exchange: "NSE",
            country: "India",
            whatItDoes: "Tata Consultancy Services is India's largest global information technology services, consulting, and digital business solutions provider. It partners with multinational enterprises to build, modernize, and operate their core enterprise applications, data architecture, cloud infrastructure, and AI systems.",
            operatingSegments: [
                BusinessSegment(name: "Banking, Financial Services & Insurance (BFSI)", sharePercentage: "~38%", description: "Core banking platform modernization, digital payments, risk & regulatory compliance solutions, and insurance underwriting tech."),
                BusinessSegment(name: "Consumer Business & Retail", sharePercentage: "~16%", description: "Omnichannel retail platforms, supply chain intelligence, predictive merchandising, and direct-to-consumer digital commerce."),
                BusinessSegment(name: "Life Sciences & Healthcare", sharePercentage: "~11%", description: "Clinical trial management, regulatory compliance automation, electronic health records, and pharmaceutical supply chain traceability."),
                BusinessSegment(name: "Manufacturing & Utilities", sharePercentage: "~10%", description: "Industrial IoT, connected smart factories, digital twins, and energy transition management software."),
                BusinessSegment(name: "Communication, Media & Tech (CMT)", sharePercentage: "~15%", description: "5G network cloudification, customer care automation, and streaming platform engineering.")
            ],
            productsAndPlatforms: [
                "TCS BaNCS (Global core banking, capital markets, and insurance engine powering 450+ financial institutions)",
                "TCS AI WisdomNext (Enterprise GenAI aggregation and multi-model deployment platform)",
                "Ignio (Autonomous AIOps software that predicts and auto-resolves enterprise IT failures)",
                "TCS TwinX (Enterprise digital twin simulator for supply chain and organizational modeling)",
                "TCS OmniStore (Unified retail POS and headless commerce platform)"
            ],
            revenueModel: [
                "Time & Materials (T&M) contracts billing enterprise client hours for consulting and specialized software engineering.",
                "Multi-year Fixed-Price outsourcing agreements delivering end-to-end IT maintenance, cloud management, and application development.",
                "IP & Software Licensing recurring revenue from proprietary platforms like TCS BaNCS and Ignio.",
                "Transformational cloud migration and AI adoption milestones delivered across multi-quarter programs."
            ],
            targetMarkets: [
                "North America (approx. 50% of revenue)",
                "United Kingdom & Continental Europe (approx. 32% of revenue)",
                "India & Asia-Pacific (approx. 18% of revenue)"
            ],
            secularGrowthDrivers: [
                "Enterprise AI Modernization: Global corporations migrating legacy mainframe workflows to cloud AI architecture.",
                "Vendor Consolidation: Large Fortune 500 enterprises reducing IT vendors and awarding mega-deals ($500M+) to tier-1 leaders like TCS.",
                "Cybersecurity & Regulatory Mandates: Stricter international compliance requiring persistent IT infrastructure upgrades."
            ],
            keyBusinessRisks: [
                "Macro Discretionary Spending Delays: Corporate slowdowns in the US or Europe can pause non-essential digital transformation projects.",
                "Wage Inflation & Talent Utilization: High onshore billing costs and employee wage revisions compress operating margins.",
                "Currency Fluctuations: TCS earns ~80% of revenue in USD/EUR/GBP while incurring significant delivery costs in INR.",
                "GenAI Disruption: Automated code generation tools could reduce required billing hours for commoditized maintenance work."
            ],
            keyMetricsToMonitor: [
                "Total Contract Value (TCV) Deal Wins (Quarterly order intake health)",
                "Operating Margin (EBIT Margin target of 24% - 26%)",
                "LTM Attrition Rate (Employee retention and talent cost stability)",
                "BFSI Vertical Revenue Trajectory (Indicator of global enterprise discretionary budget health)"
            ],
            baselineFinancialNotes: [
                "Maintains a debt-free balance sheet with industry-leading ROE (>40%).",
                "Consistently distributes over 80% of net free cash flows as shareholder dividends and buybacks."
            ]
        )

        // ==========================================
        // 2. NVIDIA CORPORATION (NVDA)
        // ==========================================
        store["NVDA"] = VerifiedCompanyProfile(
            symbol: "NVDA",
            companyName: "NVIDIA Corporation",
            sector: "Technology",
            industry: "Semiconductors & AI Hardware",
            exchange: "NASDAQ",
            country: "United States",
            whatItDoes: "NVIDIA is the global pioneer in accelerated computing. It designs high-performance graphics processing units (GPUs), AI accelerators, specialized networking hardware, and the CUDA software ecosystem that powers modern artificial intelligence, high-performance computing, data centers, and advanced graphics.",
            operatingSegments: [
                BusinessSegment(name: "Compute & Networking (Data Center)", sharePercentage: "~88%", description: "Accelerated GPU computing architectures (Blackwell, Hopper, H100/H200), Quantum InfiniBand networking, and AI enterprise platforms."),
                BusinessSegment(name: "Gaming & AI PC", sharePercentage: "~9%", description: "GeForce RTX discrete GPUs for PC gamers, digital creators, and on-device AI workstation applications."),
                BusinessSegment(name: "Professional Visualization", sharePercentage: "~2%", description: "RTX workstations for 3D modeling, computer-aided design (CAD), medical imaging, and architectural visualization."),
                BusinessSegment(name: "Automotive & Robotics", sharePercentage: "~1%", description: "NVIDIA DRIVE platform powering autonomous vehicle perception, cockpit software, and Isaac robotics simulation.")
            ],
            productsAndPlatforms: [
                "Blackwell & Hopper AI Accelerators (GB200, B200, H100, H200 tensor core GPUs)",
                "CUDA Software Architecture (Proprietary parallel programming model with 5M+ registered developers)",
                "Quantum InfiniBand & Spectrum-X Ethernet (Ultra-low latency data center interconnect networking)",
                "NVIDIA AI Enterprise & NIM (Microservices runtime for deploying commercial foundation models)",
                "Omniverse (Industrial digital twin and physically accurate simulation platform)"
            ],
            revenueModel: [
                "Data Center Hardware Sales: High-margin shipments of GPU clusters, NVLink switches, and integrated HGX/DGX server boards to cloud hyperscalers (Microsoft, AWS, Google, Meta).",
                "Networking Systems: Sales of InfiniBand and high-speed Ethernet fabric to connect thousands of GPUs with zero packet loss.",
                "Software & Service Subscriptions: Recurring licenses for NVIDIA AI Enterprise ($4,500/GPU/year) and DGX Cloud capacity.",
                "Consumer GPU Channel: Wholesale distribution of discrete graphics processors to board partners (ASUS, MSI, Gigabyte)."
            ],
            targetMarkets: [
                "Cloud Service Providers & Hyperscalers (Microsoft Azure, AWS, Google Cloud, Meta)",
                "Sovereign AI Nations & Supercomputing Research Institutes",
                "Automotive OEMs & Robotics Manufacturers",
                "Global PC Gaming & Creative Professionals"
            ],
            secularGrowthDrivers: [
                "Generative AI Inference & Training: Exponential demand for compute capacity to run frontier large multimodal models.",
                "Sovereign AI Initiatives: Governments funding national AI computing infrastructure to preserve data sovereignty.",
                "Industrial Digital Twins: Automotive and manufacturing plants simulating physical factories before construction."
            ],
            keyBusinessRisks: [
                "Hyperscaler Customer Concentration: Top 4 tech giants account for a significant share of data center GPU revenues.",
                "Foundry & Packaging Bottlenecks: Dependency on TSMC for advanced semiconductor fabrication and CoWoS packaging.",
                "Geopolitical & Export Restrictions: US Department of Commerce regulations restricting shipments of advanced chips to certain markets.",
                "Custom Silicon Competition: Major cloud customers developing internal ASICs (Google TPU, AWS Trainium, Meta MTIA)."
            ],
            keyMetricsToMonitor: [
                "Data Center Revenue Growth (Quarter-over-Quarter momentum)",
                "Gross Margin Percentage (Indicator of pricing power and product mix, benchmark ~70-75%)",
                "Hyperscaler Capital Expenditure (Capex budgets of MSFT, META, GOOGL, AMZN)",
                "Supply Chain Delivery Lead Times (TSMC packaging capacity and rack deployment pace)"
            ],
            baselineFinancialNotes: [
                "Commands premium operating margins exceeding 50% during the current AI compute cycle.",
                "Substantial net cash position with active share repurchase programs."
            ]
        )

        // ==========================================
        // 3. INFOSYS LTD (INFY.NS)
        // ==========================================
        store["INFY.NS"] = VerifiedCompanyProfile(
            symbol: "INFY.NS",
            companyName: "Infosys Ltd",
            sector: "Technology",
            industry: "IT Services & Consulting",
            exchange: "NSE",
            country: "India",
            whatItDoes: "Infosys is a global leader in next-generation digital services and consulting. It enables enterprises across 50+ countries to navigate their digital transformation through cloud platforms, AI-first solutions, enterprise package implementations, and application engineering.",
            operatingSegments: [
                BusinessSegment(name: "Financial Services", sharePercentage: "~28%", description: "Retail banking, digital wealth management, lending automation, and capital market trading systems."),
                BusinessSegment(name: "Retail, CPG & Logistics", sharePercentage: "~15%", description: "Supply chain resilience, warehouse management, and digital customer engagement."),
                BusinessSegment(name: "Communication, Telecom & OEM", sharePercentage: "~12%", description: "BSS/OSS modernization, network automation, and customer experience operations."),
                BusinessSegment(name: "Energy, Utilities & Services", sharePercentage: "~13%", description: "Grid management, smart metering, renewables integration, and utility billing systems."),
                BusinessSegment(name: "Manufacturing & Hi-Tech", sharePercentage: "~22%", description: "Smart factory execution, PLM engineering, and semiconductor software solutions.")
            ],
            productsAndPlatforms: [
                "Infosys Topaz (AI-first suite of generative AI services, platforms, and cognitive solutions)",
                "Infosys Cobalt (Cloud ecosystem comprising 300+ blueprints and 35,000 cloud assets)",
                "Finacle (Global core banking software suite used by top commercial and retail banks)",
                "Infosys Equinox (Headless digital commerce platform for enterprise brands)"
            ],
            revenueModel: [
                "Fixed-price and milestone-based project implementation contracts.",
                "Time and materials professional services billing for developers and technical consultants.",
                "Annual maintenance and managed services agreements for cloud and IT estates.",
                "Software licensing and SaaS fees from the Finacle banking platform."
            ],
            targetMarkets: [
                "North America (approx. 59% of revenue)",
                "Europe (approx. 27% of revenue)",
                "Rest of World & India (approx. 14% of revenue)"
            ],
            secularGrowthDrivers: [
                "Cloud Migration & Optimization: Continuing shift of on-premise enterprise software into hybrid cloud environments.",
                "Generative AI Implementation: Enterprises seeking certified integration partners to build custom corporate AI workflows.",
                "Digital Banking Core Replacement: Emerging market and regional European banks replacing legacy transaction engines with Finacle."
            ],
            keyBusinessRisks: [
                "North American Tech Spending Cycles: Exposure to BFSI and telecom discretionary spending cutbacks.",
                "Subcontractor & Onsite Costs: Tightening work visa rules in destination markets impacting onsite employee deployment.",
                "Price Compression: Aggressive bidding from global and Indian peers on commoditized application maintenance."
            ],
            keyMetricsToMonitor: [
                "Large Deal Total Contract Value (TCV)",
                "Operating Margin Guidance (Historical band of 20% - 22%)",
                "Voluntary Attrition Rate & Utilization Percentage",
                "Digital Revenue Share as a percentage of total turnover"
            ]
        )

        // ==========================================
        // 4. RELIANCE INDUSTRIES (RELIANCE.NS)
        // ==========================================
        store["RELIANCE.NS"] = VerifiedCompanyProfile(
            symbol: "RELIANCE.NS",
            companyName: "Reliance Industries Ltd",
            sector: "Energy & Conglomerate",
            industry: "Oil, Telecom & Retail",
            exchange: "NSE",
            country: "India",
            whatItDoes: "Reliance Industries is India's largest private enterprise. It operates world-scale refining and petrochemical complexes, India's largest telecommunications network (Jio), the country's most extensive retail chain (Reliance Retail), and is executing a massive green energy manufacturing pivot.",
            operatingSegments: [
                BusinessSegment(name: "Oil to Chemicals (O2C)", sharePercentage: "~58%", description: "World's largest single-location refinery complex in Jamnagar producing transportation fuels, polymers, and petrochemicals."),
                BusinessSegment(name: "Digital Services (Jio)", sharePercentage: "~14%", description: "Pan-India 5G/4G broadband network, 5G standalone wireless services, and cloud digital applications with 470M+ subscribers."),
                BusinessSegment(name: "Consumer Retail (Reliance Retail)", sharePercentage: "~24%", description: "Nationwide chain of 18,000+ stores spanning grocery, consumer electronics, fashion & lifestyle, and digital grocery (JioMart)."),
                BusinessSegment(name: "Oil & Gas Exploration & Green Energy", sharePercentage: "~4%", description: "Deepwater natural gas production from the KG D6 basin and multi-gigawatt solar, battery, and green hydrogen giga-factories.")
            ],
            productsAndPlatforms: [
                "Jio True 5G & JioFiber (High-speed wireless and home broadband network)",
                "JioCinema & JioSaavn (Digital entertainment, live sports streaming, and music platforms)",
                "Reliance Fresh, Smart Bazaar & Digital (Omnichannel physical grocery and electronics retail)",
                "JioMart (Hyperlocal e-commerce integration with local kirana stores)",
                "Dhirubhai Ambani Green Energy Giga Complex (Solar modules, electrolyzers, and storage batteries)"
            ],
            revenueModel: [
                "Refining Margins & Petrochemical Spreads: Gross Refining Margin (GRM) earned by processing crude oil into high-value fuels.",
                "Telecom ARPU: Monthly prepaid and postpaid subscription tariffs from 470M+ cellular and home broadband subscribers.",
                "Retail Sales: Direct merchandise markups across grocery, apparel, electronics, and wholesale consumer goods.",
                "Domestic Natural Gas Tariffs: Governed gas pricing earned on daily output from deepwater offshore fields."
            ],
            targetMarkets: [
                "Domestic Indian Consumer Market (Jio telecom and Reliance Retail footprint)",
                "Global Refined Products & Petrochemicals Export Market (Middle East, Europe, Southeast Asia)"
            ],
            secularGrowthDrivers: [
                "Digital Data Consumption: Surging Indian mobile data usage driving 5G upgrades and ARPU growth.",
                "Formalization of Indian Retail: Consumer shift from unorganized mom-and-pop stores to modern retail and quick commerce.",
                "Green Energy Manufacturing: Government PLI subsidies and domestic demand for solar modules and energy storage."
            ],
            keyBusinessRisks: [
                "Global Refining Margin Volatility: Fluctuating Brent crude prices and refining crack spreads.",
                "High Capital Expenditure: Ongoing multi-billion-dollar investments into green energy giga-factories and 5G.",
                "Regulatory Pricing Caps: Government windfall taxes on petroleum exports or administered domestic gas caps."
            ],
            keyMetricsToMonitor: [
                "Average Revenue Per User (ARPU) in Jio Telecom",
                "Gross Refining Margin (GRM) premium over Singapore benchmark",
                "Retail Footfall & Same-Store Sales Growth (SSSG)",
                "Net Debt to EBITDA Ratio"
            ]
        )

        // ==========================================
        // 5. HDFC BANK (HDFCBANK.NS)
        // ==========================================
        store["HDFCBANK.NS"] = VerifiedCompanyProfile(
            symbol: "HDFCBANK.NS",
            companyName: "HDFC Bank Ltd",
            sector: "Financial Services",
            industry: "Private Commercial Banking",
            exchange: "NSE",
            country: "India",
            whatItDoes: "HDFC Bank is India's largest private sector bank. Following its landmark merger with parent mortgage giant HDFC Ltd, it provides a comprehensive suite of commercial, retail, mortgage, auto, microfinance, and transactional banking services across 8,500+ branches.",
            operatingSegments: [
                BusinessSegment(name: "Retail Banking & Mortgages", sharePercentage: "~54%", description: "Home loans, auto loans, personal credit lines, credit cards, and retail savings deposits."),
                BusinessSegment(name: "Wholesale & Corporate Banking", sharePercentage: "~32%", description: "Working capital facilities, term lending, trade finance, and cash management for Indian conglomerates and mid-tier corporates."),
                BusinessSegment(name: "Treasury & Capital Markets", sharePercentage: "~14%", description: "Government bond portfolios, interest rate risk management, foreign exchange dealing, and liquidity reserves.")
            ],
            productsAndPlatforms: [
                "PayZapp & SmartBuy (Digital payments, consumer shopping, and reward ecosystem)",
                "HDFC Vyapar (Merchant QR and soundbox payment solution for small businesses)",
                "HDFC Bank OneView (Account aggregation and open banking platform)",
                "SmartWealth (Direct digital mutual fund and securities investment engine)"
            ],
            revenueModel: [
                "Net Interest Income (NII): Spread earned between interest received on loans/mortgages and interest paid on retail deposits.",
                "Fee-Based Income: Credit card merchant fees, loan processing fees, wealth management commissions, and trade finance guarantees.",
                "Treasury Gains: Trading profits on sovereign bond portfolios and corporate foreign currency hedging."
            ],
            targetMarkets: [
                "Urban, Semi-Urban, and Rural Indian Households",
                "Micro, Small, and Medium Enterprises (MSMEs)",
                "Large Indian Corporations & Multinational Subsidiaries"
            ],
            secularGrowthDrivers: [
                "Cross-Selling to Mortgage Customers: Converting millions of inherited mortgage borrowers into full-service bank account holders.",
                "Credit Penetration: Low per-capita debt-to-GDP in India driving long-term demand for retail unsecured and secured credit.",
                "Branch Network Maturation: Hundreds of newly opened semi-urban branches reaching operational profitability."
            ],
            keyBusinessRisks: [
                "Deposit Mobilization Pressure: Slower deposit growth compared to loan demand forcing higher interest payouts to savers.",
                "Net Interest Margin (NIM) Compression: Post-merger integration costs and higher cost of borrowings.",
                "Asset Quality Cycles: Potential rise in non-performing assets (NPAs) during macroeconomic or rural economic shocks."
            ],
            keyMetricsToMonitor: [
                "Net Interest Margin (NIM, typically tracked around 3.4% - 3.7%)",
                "Gross & Net Non-Performing Asset (GNPA / NNPA) percentages",
                "Credit-to-Deposit (CD) Ratio (Merger normalization trajectory)",
                "CASA (Current & Savings Account) Ratio"
            ]
        )

        // ==========================================
        // 6. APPLE INC (AAPL)
        // ==========================================
        store["AAPL"] = VerifiedCompanyProfile(
            symbol: "AAPL",
            companyName: "Apple Inc",
            sector: "Technology",
            industry: "Consumer Electronics & Services",
            exchange: "NASDAQ",
            country: "United States",
            whatItDoes: "Apple designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories, supported by a tightly integrated ecosystem of digital services, app distribution, cloud storage, and subscription media.",
            operatingSegments: [
                BusinessSegment(name: "iPhone", sharePercentage: "~52%", description: "Premium flagship smartphone lineup powered by custom Apple Silicon A-series chips and iOS software."),
                BusinessSegment(name: "Services", sharePercentage: "~24%", description: "App Store commissions, iCloud subscriptions, Apple Pay, Apple Music, Apple TV+, and Google search licensing."),
                BusinessSegment(name: "Wearables, Home & Accessories", sharePercentage: "~9%", description: "Apple Watch, AirPods, HomePod, Beats headphones, and peripheral hardware accessories."),
                BusinessSegment(name: "Mac", sharePercentage: "~8%", description: "MacBook Air, MacBook Pro, and Mac Studio computers powered by energy-efficient M-series silicon."),
                BusinessSegment(name: "iPad", sharePercentage: "~7%", description: "iPad Pro, Air, and mini tablets for productivity, education, and creative design.")
            ],
            productsAndPlatforms: [
                "iPhone (Global smartphone benchmark driving the core hardware ecosystem)",
                "Apple Intelligence (Personal AI system integrated into iOS, iPadOS, and macOS)",
                "App Store & Apple Services (High-margin ecosystem with over 1 billion active paid subscriptions)",
                "Apple Silicon (M-series and A-series custom ARM processors delivering class-leading performance per watt)",
                "Apple Watch & Health Ecosystem (Vital biometric tracking and consumer digital health)"
            ],
            revenueModel: [
                "High-Margin Hardware Sales: Premium retail and carrier trade-in margins across iPhone, Mac, and Wearables.",
                "Recurring Subscription Services: Monthly and annual recurring fees from iCloud+, Apple One, Music, and Arcade.",
                "Ecosystem Marketplace Commissions: 15% to 30% take rates on third-party digital purchases and subscriptions through the App Store.",
                "Licensing Agreements: Multi-billion-dollar default search engine placement fees from Alphabet."
            ],
            targetMarkets: [
                "Global High-Income Consumer Base (2.2+ Billion Active Installed Device Base)",
                "Creative Professionals, Software Engineers, and Corporate Enterprise Workspaces"
            ],
            secularGrowthDrivers: [
                "Installed Base Expansion: Consistent conversion of Android switchers in fast-growing markets like India and Latin America.",
                "Services Revenue Mix: Continued expansion of high-margin software subscriptions raising overall corporate gross margins.",
                "Apple Intelligence Upgrade Cycle: On-device generative AI features prompting enterprise and consumer phone upgrades."
            ],
            keyBusinessRisks: [
                "Regulatory & Antitrust Scrutiny: Digital Markets Act (DMA) in Europe and US DOJ lawsuits challenging App Store commission structures.",
                "Greater China Sales Volatility: Competition from domestic Chinese smartphone manufacturers (Huawei, Xiaomi).",
                "Supply Chain Concentration: Reliance on manufacturing partners like Foxconn and geopolitical exposure in East Asia."
            ],
            keyMetricsToMonitor: [
                "Active Installed Device Base (Foundation for services monetization)",
                "Services Segment Gross Margin (Benchmark >70%)",
                "iPhone Upgrade Cycle Pace & Average Selling Price (ASP)",
                "Shareholder Capital Return (Annual buybacks and dividend growth)"
            ]
        )

        // ==========================================
        // 7. MICROSOFT CORPORATION (MSFT)
        // ==========================================
        store["MSFT"] = VerifiedCompanyProfile(
            symbol: "MSFT",
            companyName: "Microsoft Corporation",
            sector: "Technology",
            industry: "Software & Cloud Computing",
            exchange: "NASDAQ",
            country: "United States",
            whatItDoes: "Microsoft is a global technology powerhouse delivering commercial cloud infrastructure (Azure), enterprise software suites (Microsoft 365), developer tools (GitHub), AI copilot services (partnership with OpenAI), professional social networking (LinkedIn), and gaming platforms (Xbox).",
            operatingSegments: [
                BusinessSegment(name: "Intelligent Cloud", sharePercentage: "~43%", description: "Azure public cloud computing, Windows Server, SQL Server, and enterprise support services."),
                BusinessSegment(name: "Productivity & Business Processes", sharePercentage: "~32%", description: "Microsoft 365 commercial & consumer subscriptions, LinkedIn, Dynamics 365 enterprise ERP/CRM."),
                BusinessSegment(name: "More Personal Computing", sharePercentage: "~25%", description: "Windows OEM licenses, Surface devices, Xbox gaming consoles, and Activision Blizzard game content.")
            ],
            productsAndPlatforms: [
                "Azure Cloud Platform (World's second largest enterprise cloud computing provider)",
                "Microsoft 365 Copilot (Enterprise GenAI assistant embedded in Word, Excel, Teams, and Outlook)",
                "GitHub & GitHub Copilot (Largest software developer platform and automated code completion tool)",
                "Xbox & Activision Blizzard (Gaming subscription ecosystem including Game Pass, Call of Duty, and Minecraft)"
            ],
            revenueModel: [
                "Cloud Consumption Billing: Pay-as-you-go and reserved instance fees for Azure compute, storage, and AI inference capacity.",
                "Per-Seat SaaS Subscriptions: Recurring monthly and annual enterprise license fees for Microsoft 365 and Copilot ($30/user/mo).",
                "Developer & Professional Licenses: GitHub enterprise seats and LinkedIn recruiter/premium subscriptions.",
                "Gaming & Hardware: Hardware console sales and recurring Xbox Game Pass subscriptions."
            ],
            targetMarkets: [
                "Global Enterprises, Governments, and SMBs",
                "Over 100 Million Software Developers (GitHub)",
                "Worldwide PC Consumers and Gamers"
            ],
            secularGrowthDrivers: [
                "Enterprise AI Adoption: Azure OpenAI Service enabling corporate clients to build custom enterprise AI applications.",
                "Hybrid Cloud Migration: Enterprise workloads transitioning from on-premise servers to Azure.",
                "Copilot Monetization: Upselling standard M365 commercial seats to higher-priced Copilot tiers."
            ],
            keyBusinessRisks: [
                "Massive AI Infrastructure Capex: Heavy spending on data centers, cooling, and GPUs before AI software revenue fully scales.",
                "Cloud Competition: Aggressive pricing and feature competition from Amazon Web Services (AWS) and Google Cloud.",
                "Cybersecurity Incidents: Security breaches of enterprise cloud estates damaging institutional trust."
            ],
            keyMetricsToMonitor: [
                "Azure & Cloud Services Revenue Growth Percentage (Constant Currency)",
                "Commercial Remaining Performance Obligation (RPO / Order Backlog)",
                "Microsoft 365 Commercial Average Revenue Per User (ARPU)",
                "Quarterly Capital Expenditures (Data Center Infrastructure Spend)"
            ]
        )

        // ==========================================
        // 8. ALPHABET INC (GOOGL)
        // ==========================================
        store["GOOGL"] = VerifiedCompanyProfile(
            symbol: "GOOGL",
            companyName: "Alphabet Inc",
            sector: "Communication Services",
            industry: "Internet Content & Search",
            exchange: "NASDAQ",
            country: "United States",
            whatItDoes: "Alphabet is the parent company of Google, the world's leading search engine and digital advertising ecosystem. Its operations encompass Google Search, YouTube, Android OS, Google Cloud enterprise computing, Google Workspace, and autonomous driving research (Waymo).",
            operatingSegments: [
                BusinessSegment(name: "Google Services (Search & Other)", sharePercentage: "~57%", description: "Google.com search ads, performance advertising, Play Store app distribution fees, and hardware devices."),
                BusinessSegment(name: "YouTube Advertising", sharePercentage: "~10%", description: "Video brand advertising, direct response ads, and YouTube Shorts monetization."),
                BusinessSegment(name: "Google Cloud (GCP)", sharePercentage: "~12%", description: "Enterprise infrastructure, BigQuery analytics, Vertex AI development platform, and Google Workspace."),
                BusinessSegment(name: "Google Subscriptions, Platforms & Devices", sharePercentage: "~14%", description: "YouTube TV, YouTube Music/Premium subscriptions, Pixel hardware, and Nest smart home devices."),
                BusinessSegment(name: "Other Bets", sharePercentage: "~1%", description: "Moonshot ventures including Waymo autonomous robotaxis and Verily life sciences.")
            ],
            productsAndPlatforms: [
                "Google Search & Gemini (Global search standard and generative AI search summaries)",
                "YouTube (World's dominant video streaming platform with 2B+ monthly logged-in users)",
                "Google Cloud Platform & Vertex AI (High-performance enterprise data analytics and AI infrastructure)",
                "Android OS (World's most widely deployed mobile operating system powering 3B+ active devices)",
                "Waymo (Commercial autonomous ride-hailing service operating in major US cities)"
            ],
            revenueModel: [
                "Cost-per-Click (CPC) and Impression (CPM) Digital Advertising on Search, Maps, and YouTube.",
                "Cloud Compute & AI Platform Consumption on GCP and enterprise Workspace seat subscriptions.",
                "Consumer Subscriptions for YouTube Premium, YouTube TV, and Google One storage.",
                "Hardware Unit Sales: Pixel smartphones, tablets, and smart home speakers."
            ],
            targetMarkets: [
                "Global Internet Users across all continents",
                "Small and Large Advertising Businesses Worldwide",
                "Enterprise IT Departments deploying cloud data lakes and AI"
            ],
            secularGrowthDrivers: [
                "Generative Search Integration: AI Overviews maintaining Google Search engagement and monetization.",
                "Google Cloud Operating Leverage: GCP scaling revenues with expanding operating profit margins.",
                "Autonomous Mobility: Waymo commercial scaling across major metropolitan ride-hail markets."
            ],
            keyBusinessRisks: [
                "Antitrust & Monopolization Rulings: US judicial rulings regarding default search distribution contracts.",
                "Search Cannibalization: Emerging conversational AI search alternatives challenging traditional keyword queries.",
                "Cyclical Advertising Sensitivity: Digital ad spend slowing during broader macroeconomic or consumer downturns."
            ],
            keyMetricsToMonitor: [
                "Google Search & Other Advertising Revenue Growth",
                "Google Cloud Operating Margin & Annual Run-Rate",
                "YouTube Advertising & Subscription Run-Rate",
                "Capital Expenditures on Custom AI Silicon (TPUs) and Data Centers"
            ]
        )

        // ==========================================
        // 9. AMAZON.COM INC (AMZN)
        // ==========================================
        store["AMZN"] = VerifiedCompanyProfile(
            symbol: "AMZN",
            companyName: "Amazon.com Inc",
            sector: "Consumer Discretionary",
            industry: "E-Commerce & Cloud Computing",
            exchange: "NASDAQ",
            country: "United States",
            whatItDoes: "Amazon is an e-commerce, cloud computing, online advertising, and digital streaming powerhouse. It operates the world's premier online marketplace, the leading cloud infrastructure provider (Amazon Web Services), a rapidly expanding digital retail ad network, and Amazon Prime delivery services.",
            operatingSegments: [
                BusinessSegment(name: "North America Retail & Services", sharePercentage: "~60%", description: "Online store sales, third-party seller marketplace services, physical stores (Whole Foods), and domestic shipping."),
                BusinessSegment(name: "International Retail", sharePercentage: "~22%", description: "E-commerce marketplaces and Prime memberships in Europe, Japan, India, and Latin America."),
                BusinessSegment(name: "Amazon Web Services (AWS)", sharePercentage: "~18%", description: "Global leader in cloud compute, cloud storage, database management, Bedrock AI models, and custom Trainium/Inferentia silicon.")
            ],
            productsAndPlatforms: [
                "Amazon Web Services (AWS) (Pioneer and global market share leader in public cloud infrastructure)",
                "Amazon Prime (Loyalty subscription delivering fast shipping, Prime Video, and exclusive member discounts)",
                "Amazon Marketplace & Fulfillment by Amazon (FBA) (Logistics network supporting millions of independent merchants)",
                "Amazon Advertising (High-margin sponsored product ads and video commercials across Prime Video)"
            ],
            revenueModel: [
                "AWS Cloud Consumption: Infrastructure compute, S3 storage, and Bedrock AI API token usage.",
                "Retail Product Sales: Direct retail markups on first-party merchandise sold on Amazon.com.",
                "Third-Party Merchant Fees: 15% marketplace commissions plus FBA fulfillment, warehousing, and delivery fees.",
                "Advertising Services: Sponsored brand search keywords and Prime Video commercial placements."
            ],
            targetMarkets: [
                "Global Consumer E-Commerce Shoppers",
                "Third-Party Small Business Sellers and Direct-to-Consumer Brands",
                "Global Enterprises, Startups, and Public Sector Institutions on AWS"
            ],
            secularGrowthDrivers: [
                "AWS Enterprise Cloud Re-acceleration: Enterprises resuming cloud modernization and deploying generative AI on Amazon Bedrock.",
                "Regional Logistics Optimization: Inbound fulfillment network restructuring lowering cost-to-serve per package.",
                "High-Margin Ad Network Growth: Sponsored listings and Prime Video ads driving corporate operating margins higher."
            ],
            keyBusinessRisks: [
                "Cloud Market Share Competition: Azure and Google Cloud aggressively competing for enterprise AI workloads.",
                "Consumer Spending Volatility: Inflationary pressures causing discretionary shoppers to trade down on retail items.",
                "Antitrust Scrutiny: Regulatory investigations into marketplace dual role as store operator and third-party competitor."
            ],
            keyMetricsToMonitor: [
                "AWS Year-over-Year Revenue Growth & Operating Margin",
                "North America Retail Operating Income (Proof of fulfillment cost efficiency)",
                "Advertising Services Revenue Trajectory",
                "Free Cash Flow Trailing Twelve Months"
            ]
        )

        // ==========================================
        // 10. TESLA INC (TSLA)
        // ==========================================
        store["TSLA"] = VerifiedCompanyProfile(
            symbol: "TSLA",
            companyName: "Tesla Inc",
            sector: "Consumer Discretionary",
            industry: "Automobile & Clean Energy",
            exchange: "NASDAQ",
            country: "United States",
            whatItDoes: "Tesla designs, manufactures, and sells fully electric passenger vehicles, utility-scale battery energy storage systems (Megapack), solar roofs, and is developing autonomous driving software (Full Self-Driving), human-like robotics (Optimus), and artificial intelligence computing hardware.",
            operatingSegments: [
                BusinessSegment(name: "Automotive Sales & Leasing", sharePercentage: "~82%", description: "Production and direct sales of Model Y, Model 3, Cybertruck, Model S, and Model X electric vehicles."),
                BusinessSegment(name: "Energy Generation & Storage", sharePercentage: "~11%", description: "Utility-scale Megapack battery storage for grid stabilization and Powerwall residential backup systems."),
                BusinessSegment(name: "Services & Other", sharePercentage: "~7%", description: "Supercharger network fast-charging revenue, vehicle service repairs, merchandise, and auto insurance.")
            ],
            productsAndPlatforms: [
                "Model Y & Model 3 (World's top-selling electric crossover and sports sedan)",
                "Megapack & Powerwall (High-capacity lithium iron phosphate stationary energy storage systems)",
                "Full Self-Driving (FSD Supervised) (Vision-only end-to-end neural network autonomous driving software)",
                "Tesla Supercharger Network (Industry benchmark high-speed electric vehicle charging standard)",
                "Optimus Humanoid Robot & Cybercab (Next-generation AI robotics and purpose-built robotaxi platform)"
            ],
            revenueModel: [
                "Direct-to-Consumer Vehicle Sales: Automotive deliveries bypassing traditional dealership networks.",
                "Energy Storage Deployment: High-margin contract shipments of Megapack battery units to power utilities.",
                "Software Subscriptions: Upfront and monthly recurring fees for Full Self-Driving ($99/month) and Premium Connectivity.",
                "Supercharging Network Fees: Electricity dispensing margins from Tesla and non-Tesla EV owners."
            ],
            targetMarkets: [
                "Global Consumer Automotive Buyers",
                "Power Utilities, Grid Operators, and Commercial Clean Energy Developers",
                "Future Autonomous Mobility Fleet Users"
            ],
            secularGrowthDrivers: [
                "Energy Storage Hypergrowth: Global grid modernization driving multi-year order backlogs for Megapack batteries.",
                "Full Self-Driving Neural Net Breakthroughs: Transition to end-to-end AI vision software increasing take rates.",
                "Next-Gen Low-Cost Vehicle Platform: Sub-$30,000 electric vehicle expanding the addressable mass-market consumer base."
            ],
            keyBusinessRisks: [
                "EV Price Competition: Aggressive pricing and feature competition from Chinese EV manufacturers (BYD, Geely).",
                "Automotive Gross Margin Compression: Incentives and price reductions impacting profitability.",
                "Autonomous Driving Timeline & Regulation: Extended safety and regulatory approval hurdles for driverless robotaxis."
            ],
            keyMetricsToMonitor: [
                "Automotive Gross Margin excluding Regulatory Credits",
                "Megapack Energy Storage Gigawatt-Hours (GWh) Deployed",
                "Quarterly Vehicle Deliveries & Production Volume",
                "Full Self-Driving Cumulative Autonomous Miles Traveled"
            ]
        )

        self.profiles = store
    }

    public func profile(for symbol: String) -> VerifiedCompanyProfile? {
        let clean = symbol.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = profiles[clean] {
            return exact
        }
        // Try matching without extension (e.g. TCS -> TCS.NS)
        if let match = profiles.values.first(where: { $0.symbol.hasPrefix(clean) || clean.hasPrefix($0.symbol.replacingOccurrences(of: ".NS", with: "")) }) {
            return match
        }
        return nil
    }

    public func hasVerifiedProfile(for symbol: String) -> Bool {
        profile(for: symbol) != nil
    }
}
