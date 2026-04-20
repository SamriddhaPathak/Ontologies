// =============================================================================
//  MisDetect Ontology — Neo4j Property Graph Cypher Script
//  Source     : misinformation_ontology.ttl  (CAIR Nepal, v1.0.0, 2026-04-18)
//  Target     : Neo4j 5+
//  Encoding   : UTF-8
//  Author     : Samriddha Pathak, CAIR Nepal
//  Generated  : 2026-04-20
//
//  EXECUTION ORDER
//  ─────────────────────────────────────────────────────────────────────────
//  Execute sections in order 1 → 14. Constraints (Section 1) must complete
//  before any MERGE statement runs. The script is fully idempotent: safe to
//  re-run on an existing database without creating duplicates.
//
//  NODE LABELS
//  ─────────────────────────────────────────────────────────────────────────
//    :Ontology   — the owl:Ontology declaration node
//    :Class      — every owl:Class (mis: namespace + external vocab stubs)
//    :Property   — every owl:ObjectProperty / owl:DatatypeProperty
//    :Entity     — every owl:NamedIndividual / instance
//    :BlankNode  — anonymous owl:AllDisjointClasses axiom groups
//
//  RELATIONSHIP TYPES
//  ─────────────────────────────────────────────────────────────────────────
//  Schema / taxonomy
//    SUBCLASS_OF          — rdfs:subClassOf
//    EQUIVALENT_CLASS     — owl:equivalentClass  (bidirectional)
//    SKOS_BROADER         — skos:broader
//    HAS_DISJOINT_MEMBER  — blank-node → member class (owl:AllDisjointClasses)
//    REFERENCES_ONTOLOGY  — blank-node axiom group → ontology node
//    IS_DEFINED_BY        — class / property / entity → ontology node
//    IMPORTS_FROM         — ontology → external vocabulary stub node
//    DCTERMS_CREATOR      — ontology → creator entity  (dcterms:creator)
//
//  Property schema
//    HAS_DOMAIN           — property → domain class
//    HAS_RANGE            — property → range class
//    INVERSE_OF           — owl:inverseOf  (bidirectional)
//    SUBPROPERTY_OF       — rdfs:subPropertyOf
//
//  Instance / data
//    INSTANCE_OF          — rdf:type  (entity → class)
//    HAS_AUTHOR           — mis:hasAuthor
//    AUTHORED             — mis:authored  (inverse of HAS_AUTHOR)
//    HAS_CLAIM            — mis:hasClaim
//    IS_CLAIM_OF          — mis:isClaimOf  (inverse of HAS_CLAIM)
//    BELONGS_TO_DOMAIN    — mis:belongsToDomain
//    HAS_INFORMATION_LABEL — mis:hasInformationLabel
//    HAS_HASHTAG          — mis:hasHashtag
//    HAS_MENTION          — mis:hasMention
//    CONTAINS_URL         — mis:containsURL
//    PUBLISHED_VIA        — mis:publishedVia
//    PART_OF_THREAD       — mis:partOfThread
//    PART_OF_CASCADE      — mis:partOfCascade
//    IS_RETWEET_OF        — mis:isRetweetOf
//    IS_QUOTE_OF          — mis:isQuoteOf
//    IS_REPLY_TO          — mis:isReplyTo
//    USER_LOCATED_IN      — mis:userLocatedIn
//    FOLLOWS              — mis:follows
//    ANNOTATED_BY         — mis:annotatedBy
//    ANNOTATION_METHOD    — mis:annotationMethod
//    DERIVED_FROM_DATASET — mis:derivedFromDataset
//    REFUTED_BY           — mis:refutedBy
//    SUPPORTED_BY         — mis:supportedBy
// =============================================================================


// =============================================================================
//  SECTION 1 — CONSTRAINTS & INDEXES
//  Must execute first and in isolation before any MERGE.
// =============================================================================

CREATE CONSTRAINT ontology_uri   IF NOT EXISTS FOR (o:Ontology)  REQUIRE o.uri IS UNIQUE;
CREATE CONSTRAINT class_uri      IF NOT EXISTS FOR (c:Class)     REQUIRE c.uri IS UNIQUE;
CREATE CONSTRAINT property_uri   IF NOT EXISTS FOR (p:Property)  REQUIRE p.uri IS UNIQUE;
CREATE CONSTRAINT entity_uri     IF NOT EXISTS FOR (e:Entity)    REQUIRE e.uri IS UNIQUE;
CREATE CONSTRAINT blanknode_uri  IF NOT EXISTS FOR (b:BlankNode) REQUIRE b.uri IS UNIQUE;

CREATE INDEX class_name          IF NOT EXISTS FOR (c:Class)    ON (c.localName);
CREATE INDEX class_qualified_name IF NOT EXISTS FOR (c:Class)    ON (c.localNameQualified);
CREATE INDEX entity_name          IF NOT EXISTS FOR (e:Entity)   ON (e.localName);
CREATE INDEX property_name        IF NOT EXISTS FOR (p:Property) ON (p.localName);


// =============================================================================
//  SECTION 2 — ONTOLOGY DECLARATION NODE
// =============================================================================

MERGE (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
SET   o.localName        = "misinformation",
      o.prefix           = "mis",
      o.title            = "MisDetect: A Multi-Domain Misinformation Detection Ontology for Social Media",
      o.description      = "An OWL 2 DL ontology for formal representation, classification, and reasoning about misinformation in Twitter/X data across Political, Educational, and Healthcare domains. The ontology aligns with SIOC, PROV-O, NIF, and Schema.org to ensure interoperability with existing Semantic Web resources. Developed by the Centre for Artificial Intelligence Research Nepal (CAIR Nepal).",
      o.dc_creator       = "Samriddha Pathak",
      o.dc_contributor   = "Samriddha Pathak (CAIR Nepal Research Group)",
      o.dc_publisher     = "CAIR Nepal",
      o.dc_rights        = "This ontology is distributed under the Creative Commons Attribution 4.0 International License.",
      o.dc_subject       = "Misinformation Detection, Social Media, Knowledge Representation, OWL 2, Twitter",
      o.dc_language      = "en",
      o.dcterms_created  = "2026-01-01",
      o.dcterms_modified = "2026-04-18",
      o.dcterms_license  = "https://creativecommons.org/licenses/by/4.0/",
      o.dcterms_identifier = "http://cair-nepal.org/ontology/misinformation",
      o.versionIRI       = "http://cair-nepal.org/ontology/misinformation/1.0.0",
      o.versionInfo      = "1.0.0",
      o.priorVersion     = "http://cair-nepal.org/ontology/misinformation/0.9.0",
      o.comment          = "MisDetect provides a comprehensive schema for modelling tweet-level misinformation. It captures provenance, user credibility, propagation structure, domain specificity, and annotation provenance in a single coherent OWL 2 DL knowledge graph.",
      o.seeAlso          = "https://github.com/cair-nepal/misdetect-ontology",
      o.skos_scopeNote   = "This ontology reuses concepts from SIOC (sioc:Post, sioc:UserAccount), PROV-O (prov:Entity, prov:Activity, prov:Agent), NIF (nif:String, nif:Context), OA (oa:Annotation, oa:TextualBody), and Schema.org (schema:Person, schema:Place).";


// =============================================================================
//  SECTION 3 — EXTERNAL VOCABULARY CLASS STUBS  (10 external classes)
//  Created before mis: classes so SUBCLASS_OF edges can always resolve.
//  All external localNames use prefix_LocalName format (e.g. prov_Entity)
//  to avoid index collisions with mis: class localNames and Neo4j labels.
// =============================================================================

MERGE (c:Class {uri: "http://rdfs.org/sioc/ns#Post"})
SET c.localName = "sioc_Post", c.prefix = "sioc", c.label = "sioc:Post", c.localNameQualified = "sioc:Post";

MERGE (c:Class {uri: "http://rdfs.org/sioc/ns#UserAccount"})
SET c.localName = "sioc_UserAccount", c.prefix = "sioc", c.label = "sioc:UserAccount", c.localNameQualified = "sioc:UserAccount";

MERGE (c:Class {uri: "http://www.w3.org/ns/prov#Entity"})
SET c.localName = "prov_Entity", c.prefix = "prov", c.label = "prov:Entity", c.localNameQualified = "prov:Entity";

MERGE (c:Class {uri: "http://www.w3.org/ns/prov#Agent"})
SET c.localName = "prov_Agent", c.prefix = "prov", c.label = "prov:Agent", c.localNameQualified = "prov:Agent";

MERGE (c:Class {uri: "http://www.w3.org/ns/prov#Activity"})
SET c.localName = "prov_Activity", c.prefix = "prov", c.label = "prov:Activity", c.localNameQualified = "prov:Activity";

MERGE (c:Class {uri: "http://xmlns.com/foaf/0.1/Agent"})
SET c.localName = "foaf_Agent", c.prefix = "foaf", c.label = "foaf:Agent", c.localNameQualified = "foaf:Agent";

// BUG-FIX #4: foaf:Person was never created; needed for SamriddhaPathak INSTANCE_OF.
MERGE (c:Class {uri: "http://xmlns.com/foaf/0.1/Person"})
SET c.localName = "foaf_Person", c.prefix = "foaf", c.label = "foaf:Person", c.localNameQualified = "foaf:Person";

MERGE (c:Class {uri: "http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#String"})
SET c.localName = "nif_String", c.prefix = "nif", c.label = "nif:String", c.localNameQualified = "nif:String";

MERGE (c:Class {uri: "http://www.w3.org/ns/oa#Annotation"})
SET c.localName = "oa_Annotation", c.prefix = "oa", c.label = "oa:Annotation", c.localNameQualified = "oa:Annotation";

MERGE (c:Class {uri: "https://schema.org/Place"})
SET c.localName = "schema_Place", c.prefix = "schema", c.label = "schema:Place", c.localNameQualified = "schema:Place";


// =============================================================================
//  SECTION 4 — MIS: CLASS NODES  (33 classes)
// =============================================================================

// --- 4.1  SocialMediaPost ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#SocialMediaPost"})
SET c.localName    = "SocialMediaPost",
    c.prefix       = "mis",
    c.name         = "SocialMediaPost",
    c.label        = "Social Media Post",
    c.comment      = "A generic post published on any social media platform. Superclass of Tweet, enabling future extension to other platforms (Reddit, Facebook, etc.).",
    c.definition   = "A discrete unit of user-generated content published on a social networking platform.",
    c.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

// --- 4.2  Tweet ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
SET c.localName   = "Tweet",
    c.prefix      = "mis",
    c.name        = "Tweet",
    c.label       = "Tweet",
    c.comment     = "A post published on the Twitter/X platform, consisting of up to 280 characters of text, optional media, and metadata.",
    c.definition  = "A microblog post on Twitter/X, uniquely identified by a tweet ID, authored by a single User account, published at a specific timestamp.",
    c.example     = "A tweet asserting a health claim with hashtags #vaccines and #health.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.3  OriginalTweet ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#OriginalTweet"})
SET c.localName   = "OriginalTweet",
    c.prefix      = "mis",
    c.name        = "OriginalTweet",
    c.label       = "Original Tweet",
    c.comment     = "A tweet authored directly by a user and not a repost of any existing tweet.",
    c.definition  = "A first-instance tweet that constitutes the primary unit of content generation.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.4  Retweet ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#Retweet"})
SET c.localName   = "Retweet",
    c.prefix      = "mis",
    c.name        = "Retweet",
    c.label       = "Retweet",
    c.comment     = "A republication of an existing tweet by a different (or the same) user, preserving the original content.",
    c.definition  = "A derivative tweet that re-shares an OriginalTweet, contributing to information propagation.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.5  QuoteTweet ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#QuoteTweet"})
SET c.localName   = "QuoteTweet",
    c.prefix      = "mis",
    c.name        = "QuoteTweet",
    c.label       = "Quote Tweet",
    c.comment     = "A tweet that embeds and comments on another tweet, adding new textual context.",
    c.definition  = "A tweet that references and quotes an existing tweet while appending additional commentary.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.6  ReplyTweet ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#ReplyTweet"})
SET c.localName   = "ReplyTweet",
    c.prefix      = "mis",
    c.name        = "ReplyTweet",
    c.label       = "Reply Tweet",
    c.comment     = "A tweet posted in direct response to another tweet, forming a conversational thread.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.7  User ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#User"})
SET c.localName   = "User",
    c.prefix      = "mis",
    c.name        = "User",
    c.label       = "User",
    c.comment     = "A registered Twitter/X account capable of authoring, retweeting, and interacting with tweets.",
    c.definition  = "An agent on the Twitter/X platform, identified by a unique user ID and handle.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.8  VerifiedUser ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#VerifiedUser"})
SET c.localName   = "VerifiedUser",
    c.prefix      = "mis",
    c.name        = "VerifiedUser",
    c.label       = "Verified User",
    c.comment     = "A Twitter/X user whose identity has been confirmed by the platform (legacy blue check or organisation verification).",
    c.definition  = "A user account bearing official platform verification, typically associated with public figures, organisations, or journalists.",
    c.semanticNote = "VerifiedUser individuals carry mis:isVerified = true.",
    c.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

// --- 4.9  UnverifiedUser ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#UnverifiedUser"})
SET c.localName   = "UnverifiedUser",
    c.prefix      = "mis",
    c.name        = "UnverifiedUser",
    c.label       = "Unverified User",
    c.comment     = "A Twitter/X user without platform-issued identity verification.",
    c.semanticNote = "UnverifiedUser individuals carry mis:isVerified = false.",
    c.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

// --- 4.10  HighInfluenceUser ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#HighInfluenceUser"})
SET c.localName   = "HighInfluenceUser",
    c.prefix      = "mis",
    c.name        = "HighInfluenceUser",
    c.label       = "High Influence User",
    c.comment     = "A user whose follower count exceeds the domain-defined influence threshold, indicating significant reach.",
    c.definition  = "A user with a follower-to-friend ratio and absolute follower count that classify them as a macro-influencer within the dataset.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.11  BotSuspectUser ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#BotSuspectUser"})
SET c.localName   = "BotSuspectUser",
    c.prefix      = "mis",
    c.name        = "BotSuspectUser",
    c.label       = "Bot Suspect User",
    c.comment     = "A user flagged by heuristic or ML-based analysis as potentially automated rather than human.",
    c.scopeNote   = "Classification as BotSuspectUser does not constitute confirmation of automated behaviour; it signals elevated suspicion for downstream analysis.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.12  Claim ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#Claim"})
SET c.localName   = "Claim",
    c.prefix      = "mis",
    c.name        = "Claim",
    c.label       = "Claim",
    c.comment     = "A declarative assertion extracted from or implied by a tweet, amenable to truth evaluation.",
    c.definition  = "A proposition or statement that can be evaluated for factual accuracy against external knowledge sources.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.13  MisinformationClaim ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#MisinformationClaim"})
SET c.localName     = "MisinformationClaim",
    c.prefix        = "mis",
    c.name          = "MisinformationClaim",
    c.label         = "Misinformation Claim",
    c.comment       = "A claim that has been annotated as factually incorrect, misleading, or lacking credible evidentiary support.",
    c.definition    = "A verifiably false or intentionally misleading assertion disseminated via a tweet.",
    c.skos_broader  = "http://cair-nepal.org/ontology/misinformation#Claim",
    c.isDefinedBy   = "http://cair-nepal.org/ontology/misinformation";

// --- 4.14  AccurateClaim ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#AccurateClaim"})
SET c.localName     = "AccurateClaim",
    c.prefix        = "mis",
    c.name          = "AccurateClaim",
    c.label         = "Accurate Claim",
    c.comment       = "A claim that has been verified as factually correct and consistent with authoritative knowledge sources.",
    c.definition    = "A verified, factually correct assertion disseminated via a tweet.",
    c.skos_broader  = "http://cair-nepal.org/ontology/misinformation#Claim",
    c.isDefinedBy   = "http://cair-nepal.org/ontology/misinformation";

// --- 4.15  UnverifiedClaim ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#UnverifiedClaim"})
SET c.localName   = "UnverifiedClaim",
    c.prefix      = "mis",
    c.name        = "UnverifiedClaim",
    c.label       = "Unverified Claim",
    c.comment     = "A claim whose truth value has not yet been determined by fact-checking or annotation.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.16  SatiricalClaim ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#SatiricalClaim"})
SET c.localName   = "SatiricalClaim",
    c.prefix      = "mis",
    c.name        = "SatiricalClaim",
    c.label       = "Satirical Claim",
    c.comment     = "A statement that is intentionally humorous or hyperbolic, not intended as a factual assertion but potentially misread as one.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.17  Domain ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#Domain"})
SET c.localName   = "Domain",
    c.prefix      = "mis",
    c.name        = "Domain",
    c.label       = "Domain",
    c.comment     = "A thematic category classifying the subject matter of a tweet.",
    c.definition  = "A high-level topical area within which a tweet's content is situated.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.18  PoliticalDomain ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#PoliticalDomain"})
SET c.localName   = "PoliticalDomain",
    c.prefix      = "mis",
    c.name        = "PoliticalDomain",
    c.label       = "Political Domain",
    c.comment     = "Tweets relating to politics, governance, elections, policy-making, political figures, or civic affairs.",
    c.example     = "Tweets about election results, parliamentary proceedings, or political party statements.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.19  EducationalDomain ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#EducationalDomain"})
SET c.localName   = "EducationalDomain",
    c.prefix      = "mis",
    c.name        = "EducationalDomain",
    c.label       = "Educational Domain",
    c.comment     = "Tweets relating to education systems, academic research, learning institutions, curricula, or educational policy.",
    c.example     = "Tweets about university admissions, academic fraud, or educational access.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.20  HealthcareDomain ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#HealthcareDomain"})
SET c.localName   = "HealthcareDomain",
    c.prefix      = "mis",
    c.name        = "HealthcareDomain",
    c.label       = "Healthcare Domain",
    c.comment     = "Tweets relating to medicine, public health, pharmaceuticals, diseases, vaccines, or healthcare systems.",
    c.example     = "Tweets about vaccine safety, COVID-19 treatments, or medical misinformation.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.21  InformationLabel ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#InformationLabel"})
SET c.localName   = "InformationLabel",
    c.prefix      = "mis",
    c.name        = "InformationLabel",
    c.label       = "Information Label",
    c.comment     = "An annotation assigned to a tweet or claim indicating its misinformation status, derived from human annotation or automated classification.",
    c.definition  = "A categorical label that encodes the veracity assessment of a tweet or claim.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.22  AnnotationEvent ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#AnnotationEvent"})
SET c.localName   = "AnnotationEvent",
    c.prefix      = "mis",
    c.name        = "AnnotationEvent",
    c.label       = "Annotation Event",
    c.comment     = "A provenance activity recording when, by whom, and by what method a tweet was annotated with an information label.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.23  Annotator ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#Annotator"})
SET c.localName   = "Annotator",
    c.prefix      = "mis",
    c.name        = "Annotator",
    c.label       = "Annotator",
    c.comment     = "An agent (human expert or automated system) responsible for assigning information labels to tweets.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.24  HumanAnnotator ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#HumanAnnotator"})
SET c.localName   = "HumanAnnotator",
    c.prefix      = "mis",
    c.name        = "HumanAnnotator",
    c.label       = "Human Annotator",
    c.comment     = "A domain expert or crowd-sourced contributor who manually assigns veracity labels.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.25  AutomatedAnnotator ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#AutomatedAnnotator"})
SET c.localName   = "AutomatedAnnotator",
    c.prefix      = "mis",
    c.name        = "AutomatedAnnotator",
    c.label       = "Automated Annotator",
    c.comment     = "A machine learning model or rule-based system that assigns veracity labels programmatically.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.26  PropagationCascade ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#PropagationCascade"})
SET c.localName   = "PropagationCascade",
    c.prefix      = "mis",
    c.name        = "PropagationCascade",
    c.label       = "Propagation Cascade",
    c.comment     = "A directed tree or graph of retweets and quote tweets that traces how a piece of information spreads from an original tweet.",
    c.definition  = "A structured representation of the diffusion path of a tweet through a social network.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.27  Thread ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#Thread"})
SET c.localName   = "Thread",
    c.prefix      = "mis",
    c.name        = "Thread",
    c.label       = "Thread",
    c.comment     = "A sequence of reply tweets connected to an original tweet, forming a conversational structure.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.28  Hashtag ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#Hashtag"})
SET c.localName   = "Hashtag",
    c.prefix      = "mis",
    c.name        = "Hashtag",
    c.label       = "Hashtag",
    c.comment     = "A metadata tag prefixed with # used within a tweet to index content by topic.",
    c.definition  = "A user-generated topical label embedded in tweet text, enabling cross-tweet thematic discovery.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.29  Mention ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#Mention"})
SET c.localName   = "Mention",
    c.prefix      = "mis",
    c.name        = "Mention",
    c.label       = "Mention",
    c.comment     = "A reference to another Twitter/X user within a tweet, prefixed with @.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.30  URL ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#URL"})
SET c.localName   = "URL",
    c.prefix      = "mis",
    c.name        = "URL",
    c.label       = "URL",
    c.comment     = "A hyperlink included within a tweet, potentially pointing to external evidence, news sources, or misinformation amplifiers.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.31  Source ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#Source"})
SET c.localName   = "Source",
    c.prefix      = "mis",
    c.name        = "Source",
    c.label       = "Source",
    c.comment     = "The application client or platform interface through which a tweet was published (e.g., Twitter for Android, TweetDeck).",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.32  Location ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#Location"})
SET c.localName   = "Location",
    c.prefix      = "mis",
    c.name        = "Location",
    c.label       = "Location",
    c.comment     = "A geographic location self-reported by a user or geo-tagged to a tweet.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";

// --- 4.33  Dataset ---
MERGE (c:Class {uri: "http://cair-nepal.org/ontology/misinformation#Dataset"})
SET c.localName   = "Dataset",
    c.prefix      = "mis",
    c.name        = "Dataset",
    c.label       = "Dataset",
    c.comment     = "A structured collection of tweets used for misinformation detection research, characterised by its domain composition, size, and annotation methodology.",
    c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";


// =============================================================================
//  SECTION 5 — CLASS HIERARCHY (rdfs:subClassOf)
//  All MATCH operations here are safe because all Class nodes were created above.
// =============================================================================

// --- 5.1  Tweet hierarchy ---
MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#SocialMediaPost"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MATCH (parent:Class {uri: "http://www.w3.org/ns/prov#Entity"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#OriginalTweet"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#Retweet"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#QuoteTweet"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#ReplyTweet"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

// --- 5.2  User hierarchy ---
MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#User"})
MATCH (parent:Class {uri: "http://www.w3.org/ns/prov#Agent"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#User"})
MATCH (parent:Class {uri: "http://xmlns.com/foaf/0.1/Agent"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#VerifiedUser"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#User"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#UnverifiedUser"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#User"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#HighInfluenceUser"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#User"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#BotSuspectUser"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#User"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

// --- 5.3  Claim hierarchy ---
MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#Claim"})
MATCH (parent:Class {uri: "http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#String"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#MisinformationClaim"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Claim"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#AccurateClaim"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Claim"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#UnverifiedClaim"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Claim"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#SatiricalClaim"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Claim"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

// --- 5.4  Domain hierarchy ---
MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#PoliticalDomain"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Domain"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#EducationalDomain"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Domain"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#HealthcareDomain"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Domain"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

// --- 5.5  Annotation & provenance hierarchy ---
MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#InformationLabel"})
MATCH (parent:Class {uri: "http://www.w3.org/ns/oa#Annotation"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#AnnotationEvent"})
MATCH (parent:Class {uri: "http://www.w3.org/ns/prov#Activity"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

// BUG-FIX: Annotator subClassOf prov:Agent was missing a proper MERGE block
// (the external class was defined, referenced, but the edge itself was only
// attempted AFTER the external-class section, which could fail on partial runs).
MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#Annotator"})
MATCH (parent:Class {uri: "http://www.w3.org/ns/prov#Agent"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#HumanAnnotator"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Annotator"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#AutomatedAnnotator"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Annotator"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

// --- 5.6  Propagation & dataset hierarchy ---
MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#PropagationCascade"})
MATCH (parent:Class {uri: "http://www.w3.org/ns/prov#Entity"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#Thread"})
MATCH (parent:Class {uri: "http://www.w3.org/ns/prov#Entity"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#Dataset"})
MATCH (parent:Class {uri: "http://www.w3.org/ns/prov#Entity"})
MERGE (child)-[:SUBCLASS_OF]->(parent);

// --- 5.7  Location ---
MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#Location"})
MATCH (parent:Class {uri: "https://schema.org/Place"})
MERGE (child)-[:SUBCLASS_OF]->(parent);


// =============================================================================
//  SECTION 6 — OWL:EQUIVALENTCLASS EDGES
// =============================================================================

MATCH (c1:Class {uri: "http://cair-nepal.org/ontology/misinformation#SocialMediaPost"})
MATCH (c2:Class {uri: "http://rdfs.org/sioc/ns#Post"})
MERGE (c1)-[:EQUIVALENT_CLASS]->(c2)
MERGE (c2)-[:EQUIVALENT_CLASS]->(c1);

MATCH (c1:Class {uri: "http://cair-nepal.org/ontology/misinformation#User"})
MATCH (c2:Class {uri: "http://rdfs.org/sioc/ns#UserAccount"})
MERGE (c1)-[:EQUIVALENT_CLASS]->(c2)
MERGE (c2)-[:EQUIVALENT_CLASS]->(c1);


// =============================================================================
//  SECTION 7 — SKOS BROADER EDGES (between Class nodes)
//  BUG-FIX: The skos:broader property from the TTL applied to Class nodes.
//  Both property-on-node (section 4) and explicit graph edge are now present.
// =============================================================================

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#MisinformationClaim"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Claim"})
MERGE (child)-[:SKOS_BROADER]->(parent);

MATCH (child:Class {uri: "http://cair-nepal.org/ontology/misinformation#AccurateClaim"})
MATCH (parent:Class {uri: "http://cair-nepal.org/ontology/misinformation#Claim"})
MERGE (child)-[:SKOS_BROADER]->(parent);


// =============================================================================
//  SECTION 8 — OWL AllDisjointClasses BLANK NODES
//  BUG-FIX: BlankNode constraint added in Section 1; nodes now idempotent.
// =============================================================================

MERGE (b:BlankNode {uri: "blank_b1_AllDisjointClasses_TweetSubtypes"})
SET b.rdfType = "owl:AllDisjointClasses",
    b.members = [
      "http://cair-nepal.org/ontology/misinformation#OriginalTweet",
      "http://cair-nepal.org/ontology/misinformation#Retweet",
      "http://cair-nepal.org/ontology/misinformation#QuoteTweet",
      "http://cair-nepal.org/ontology/misinformation#ReplyTweet"
    ]
WITH b
UNWIND b.members AS memberUri
  MATCH (c:Class {uri: memberUri})
  MERGE (b)-[:HAS_DISJOINT_MEMBER]->(c);

MERGE (b:BlankNode {uri: "blank_b2_AllDisjointClasses_UserVerification"})
SET b.rdfType = "owl:AllDisjointClasses",
    b.members = [
      "http://cair-nepal.org/ontology/misinformation#VerifiedUser",
      "http://cair-nepal.org/ontology/misinformation#UnverifiedUser"
    ]
WITH b
UNWIND b.members AS memberUri
  MATCH (c:Class {uri: memberUri})
  MERGE (b)-[:HAS_DISJOINT_MEMBER]->(c);

MERGE (b:BlankNode {uri: "blank_b3_AllDisjointClasses_Claims"})
SET b.rdfType = "owl:AllDisjointClasses",
    b.members = [
      "http://cair-nepal.org/ontology/misinformation#MisinformationClaim",
      "http://cair-nepal.org/ontology/misinformation#AccurateClaim",
      "http://cair-nepal.org/ontology/misinformation#UnverifiedClaim",
      "http://cair-nepal.org/ontology/misinformation#SatiricalClaim"
    ]
WITH b
UNWIND b.members AS memberUri
  MATCH (c:Class {uri: memberUri})
  MERGE (b)-[:HAS_DISJOINT_MEMBER]->(c);

MERGE (b:BlankNode {uri: "blank_b4_AllDisjointClasses_Domains"})
SET b.rdfType = "owl:AllDisjointClasses",
    b.members = [
      "http://cair-nepal.org/ontology/misinformation#PoliticalDomain",
      "http://cair-nepal.org/ontology/misinformation#EducationalDomain",
      "http://cair-nepal.org/ontology/misinformation#HealthcareDomain"
    ]
WITH b
UNWIND b.members AS memberUri
  MATCH (c:Class {uri: memberUri})
  MERGE (b)-[:HAS_DISJOINT_MEMBER]->(c);

MERGE (b:BlankNode {uri: "blank_b5_AllDisjointClasses_Annotators"})
SET b.rdfType = "owl:AllDisjointClasses",
    b.members = [
      "http://cair-nepal.org/ontology/misinformation#HumanAnnotator",
      "http://cair-nepal.org/ontology/misinformation#AutomatedAnnotator"
    ]
WITH b
UNWIND b.members AS memberUri
  MATCH (c:Class {uri: memberUri})
  MERGE (b)-[:HAS_DISJOINT_MEMBER]->(c);


// =============================================================================
//  SECTION 9 — OBJECT PROPERTY NODES
//  Each property node is created with MERGE…SET (one statement).
//  HAS_DOMAIN and HAS_RANGE edges are added in separate MATCH…MERGE statements.
//  This avoids the WITH p across statement boundaries (SyntaxError) entirely.
// =============================================================================

// External property stubs needed for SUBPROPERTY_OF edges.
MERGE (ep1:Property {uri: "http://www.w3.org/ns/prov#wasAttributedTo"})
SET ep1.localName = "prov_wasAttributedTo", ep1.prefix = "prov",
    ep1.propertyType = "ObjectProperty", ep1.label = "prov:wasAttributedTo",
    ep1.localNameQualified = "prov:wasAttributedTo";

MERGE (ep2:Property {uri: "http://www.w3.org/ns/prov#wasDerivedFrom"})
SET ep2.localName = "prov_wasDerivedFrom", ep2.prefix = "prov",
    ep2.propertyType = "ObjectProperty", ep2.label = "prov:wasDerivedFrom",
    ep2.localNameQualified = "prov:wasDerivedFrom";

// --- 9.1  hasAuthor ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasAuthor"})
SET p.localName    = "hasAuthor",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.isFunctional = true,
    p.label        = "has author",
    p.comment      = "Relates a tweet to the single User who authored it. Declared functional: each tweet has exactly one author.",
    p.definition   = "The authorship relation between a tweet and its originating user account.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasAuthor"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasAuthor"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#User"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.2  authored ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#authored"})
SET p.localName    = "authored",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "authored",
    p.comment      = "Inverse of hasAuthor: relates a user to all tweets they have authored.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#authored"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#User"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#authored"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_RANGE]->(r);

MATCH (p1:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasAuthor"})
MATCH (p2:Property {uri: "http://cair-nepal.org/ontology/misinformation#authored"})
MERGE (p1)-[:INVERSE_OF]->(p2)
MERGE (p2)-[:INVERSE_OF]->(p1);

// --- 9.3  hasClaim ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasClaim"})
SET p.localName    = "hasClaim",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "has claim",
    p.comment      = "Relates a tweet to one or more claims it asserts or implies.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasClaim"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasClaim"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Claim"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.4  isClaimOf ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#isClaimOf"})
SET p.localName    = "isClaimOf",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "is claim of",
    p.comment      = "Inverse of hasClaim: relates a claim back to the tweet that expresses it.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#isClaimOf"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Claim"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#isClaimOf"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_RANGE]->(r);

MATCH (p1:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasClaim"})
MATCH (p2:Property {uri: "http://cair-nepal.org/ontology/misinformation#isClaimOf"})
MERGE (p1)-[:INVERSE_OF]->(p2)
MERGE (p2)-[:INVERSE_OF]->(p1);

// --- 9.5  belongsToDomain ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#belongsToDomain"})
SET p.localName    = "belongsToDomain",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "belongs to domain",
    p.comment      = "Assigns one or more thematic domains to a tweet.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#belongsToDomain"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#belongsToDomain"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Domain"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.6  hasInformationLabel ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasInformationLabel"})
SET p.localName    = "hasInformationLabel",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.isFunctional = true,
    p.label        = "has information label",
    p.comment      = "Associates a tweet with its veracity annotation label. Declared functional: at most one label per tweet post-annotation.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasInformationLabel"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasInformationLabel"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#InformationLabel"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.7  hasHashtag ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasHashtag"})
SET p.localName    = "hasHashtag",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "has hashtag",
    p.comment      = "Relates a tweet to hashtag entities extracted from its text.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasHashtag"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasHashtag"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Hashtag"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.8  hasMention ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasMention"})
SET p.localName    = "hasMention",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "has mention",
    p.comment      = "Relates a tweet to user mentions (@handle) present in its text.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasMention"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#hasMention"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Mention"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.9  containsURL ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#containsURL"})
SET p.localName    = "containsURL",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "contains URL",
    p.comment      = "Relates a tweet to hyperlinks embedded in its text.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#containsURL"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#containsURL"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#URL"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.10  publishedVia ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#publishedVia"})
SET p.localName    = "publishedVia",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "published via",
    p.comment      = "Identifies the platform client or application used to post the tweet.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#publishedVia"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#publishedVia"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Source"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.11  partOfThread ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#partOfThread"})
SET p.localName    = "partOfThread",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "part of thread",
    p.comment      = "Associates a tweet with the conversational thread to which it belongs.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#partOfThread"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#partOfThread"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Thread"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.12  partOfCascade ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#partOfCascade"})
SET p.localName    = "partOfCascade",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "part of cascade",
    p.comment      = "Relates a tweet (original or retweet) to its propagation cascade.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#partOfCascade"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#partOfCascade"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#PropagationCascade"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.13  isRetweetOf ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#isRetweetOf"})
SET p.localName    = "isRetweetOf",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.isFunctional = true,
    p.label        = "is retweet of",
    p.comment      = "Relates a retweet to the original tweet it reposts. Functional: a retweet has exactly one source.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#isRetweetOf"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Retweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#isRetweetOf"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#OriginalTweet"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.14  isQuoteOf ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#isQuoteOf"})
SET p.localName    = "isQuoteOf",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.isFunctional = true,
    p.label        = "is quote of",
    p.comment      = "Relates a quote tweet to the tweet it quotes and comments on.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#isQuoteOf"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#QuoteTweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#isQuoteOf"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.15  isReplyTo ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#isReplyTo"})
SET p.localName    = "isReplyTo",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "is reply to",
    p.comment      = "Relates a reply tweet to the tweet it responds to.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#isReplyTo"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#ReplyTweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#isReplyTo"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.16  userLocatedIn ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#userLocatedIn"})
SET p.localName    = "userLocatedIn",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "user located in",
    p.comment      = "Associates a user with their self-reported or inferred geographic location.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#userLocatedIn"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#User"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#userLocatedIn"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Location"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.17  follows ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#follows"})
SET p.localName    = "follows",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.isAsymmetric = true,
    p.label        = "follows",
    p.comment      = "Directed social relation: a user subscribes to another user's content feed.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#follows"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#User"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#follows"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#User"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.18  annotatedBy ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#annotatedBy"})
SET p.localName    = "annotatedBy",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "annotated by",
    p.comment      = "Relates an information label to the annotator (human or automated) who assigned it.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#annotatedBy"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#InformationLabel"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#annotatedBy"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Annotator"})
MERGE (p)-[:HAS_RANGE]->(r);

MATCH (p:Property    {uri: "http://cair-nepal.org/ontology/misinformation#annotatedBy"})
MATCH (super:Property {uri: "http://www.w3.org/ns/prov#wasAttributedTo"})
MERGE (p)-[:SUBPROPERTY_OF]->(super);

// --- 9.19  annotationMethod ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#annotationMethod"})
SET p.localName    = "annotationMethod",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "annotation method",
    p.comment      = "Links a label to the annotation activity that produced it, capturing methodology provenance.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#annotationMethod"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#InformationLabel"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#annotationMethod"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#AnnotationEvent"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.20  derivedFromDataset ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#derivedFromDataset"})
SET p.localName    = "derivedFromDataset",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "derived from dataset",
    p.comment      = "Indicates the research dataset from which this tweet instance was drawn.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#derivedFromDataset"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Tweet"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#derivedFromDataset"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#Dataset"})
MERGE (p)-[:HAS_RANGE]->(r);

MATCH (p:Property    {uri: "http://cair-nepal.org/ontology/misinformation#derivedFromDataset"})
MATCH (super:Property {uri: "http://www.w3.org/ns/prov#wasDerivedFrom"})
MERGE (p)-[:SUBPROPERTY_OF]->(super);

// --- 9.21  refutedBy ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#refutedBy"})
SET p.localName    = "refutedBy",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "refuted by",
    p.comment      = "Links a misinformation claim to an authoritative URL (fact-check article, primary source) that refutes it.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#refutedBy"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#MisinformationClaim"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#refutedBy"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#URL"})
MERGE (p)-[:HAS_RANGE]->(r);

// --- 9.22  supportedBy ---
MERGE (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#supportedBy"})
SET p.localName    = "supportedBy",
    p.prefix       = "mis",
    p.propertyType = "ObjectProperty",
    p.label        = "supported by",
    p.comment      = "Links an accurate claim to an authoritative URL that corroborates it.",
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation";

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#supportedBy"})
MATCH (d:Class    {uri: "http://cair-nepal.org/ontology/misinformation#AccurateClaim"})
MERGE (p)-[:HAS_DOMAIN]->(d);

MATCH (p:Property {uri: "http://cair-nepal.org/ontology/misinformation#supportedBy"})
MATCH (r:Class    {uri: "http://cair-nepal.org/ontology/misinformation#URL"})
MERGE (p)-[:HAS_RANGE]->(r);


// =============================================================================
//  SECTION 10 — DATATYPE PROPERTY NODES
//  BUG-FIX: HAS_DOMAIN graph edges added (range is a literal XSD type, kept
//  as a property string — no Class node needed for XSD types).
// =============================================================================

UNWIND [
  {uri: "http://cair-nepal.org/ontology/misinformation#tweetID",
   localName: "tweetID", label: "tweet ID",
   comment: "The unique numeric identifier assigned to a tweet by the Twitter/X platform.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Tweet",
   range: "xsd:string", isFunctional: true},

  {uri: "http://cair-nepal.org/ontology/misinformation#tweetText",
   localName: "tweetText", label: "tweet text",
   comment: "The full textual content of the tweet, including hashtags, mentions, and URLs.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Tweet",
   range: "xsd:string", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#tweetDate",
   localName: "tweetDate", label: "tweet date",
   comment: "The ISO 8601 timestamp at which the tweet was published on the platform.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Tweet",
   range: "xsd:dateTime", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#isMisinformation",
   localName: "isMisinformation", label: "is misinformation",
   comment: "Binary annotation flag: true if the tweet has been labelled as containing misinformation, false otherwise.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Tweet",
   range: "xsd:boolean", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#isRetweet",
   localName: "isRetweet", label: "is retweet",
   comment: "Indicates whether the tweet is a repost of an existing tweet.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Tweet",
   range: "xsd:boolean", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#hashtagList",
   localName: "hashtagList", label: "hashtag list",
   comment: "A serialised string representation of all hashtags extracted from the tweet text. For structured access use mis:hasHashtag.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Tweet",
   range: "xsd:string", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#sourceClient",
   localName: "sourceClient", label: "source client",
   comment: "The name of the application or client used to post the tweet (e.g., Twitter for Android, Twitter Web App).",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Tweet",
   range: "xsd:string", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#retweetCount",
   localName: "retweetCount", label: "retweet count",
   comment: "The number of times this tweet has been retweeted at the time of data collection.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Tweet",
   range: "xsd:nonNegativeInteger", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#likeCount",
   localName: "likeCount", label: "like count",
   comment: "The number of likes (favourites) this tweet received at the time of data collection.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Tweet",
   range: "xsd:nonNegativeInteger", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#replyCount",
   localName: "replyCount", label: "reply count",
   comment: "The number of direct replies to this tweet at the time of data collection.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Tweet",
   range: "xsd:nonNegativeInteger", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#languageCode",
   localName: "languageCode", label: "language code",
   comment: "BCP 47 language tag detected by the platform for the tweet content (e.g., en, ne, hi).",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Tweet",
   range: "xsd:language", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#sensitiveContent",
   localName: "sensitiveContent", label: "sensitive content",
   comment: "Platform flag indicating whether the tweet has been marked as potentially sensitive.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Tweet",
   range: "xsd:boolean", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#userID",
   localName: "userID", label: "user ID",
   comment: "The unique numeric identifier assigned to a user account by the Twitter/X platform.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:string", isFunctional: true},

  {uri: "http://cair-nepal.org/ontology/misinformation#userName",
   localName: "userName", label: "user name",
   comment: "The Twitter/X handle (@username) of the user account.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:string", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#userDisplayName",
   localName: "userDisplayName", label: "user display name",
   comment: "The human-readable display name of the user, distinct from the handle.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:string", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#userLocation",
   localName: "userLocation", label: "user location",
   comment: "The self-reported geographic location string from the user's profile.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:string", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#userDescription",
   localName: "userDescription", label: "user description",
   comment: "The biography or self-description text from the user's Twitter/X profile.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:string", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#userCreated",
   localName: "userCreated", label: "user created",
   comment: "The ISO 8601 timestamp at which the Twitter/X account was created.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:dateTime", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#followerCount",
   localName: "followerCount", label: "follower count",
   comment: "The number of accounts following this user at the time of data collection.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:nonNegativeInteger", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#friendCount",
   localName: "friendCount", label: "friend count",
   comment: "The number of accounts this user is following at the time of data collection.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:nonNegativeInteger", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#favouriteCount",
   localName: "favouriteCount", label: "favourite count",
   comment: "The cumulative number of tweets the user has liked over their account lifetime.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:nonNegativeInteger", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#tweetCount",
   localName: "tweetCount", label: "tweet count",
   comment: "The total number of tweets (including retweets) posted by this user over their account lifetime.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:nonNegativeInteger", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#isVerified",
   localName: "isVerified", label: "is verified",
   comment: "Boolean flag indicating whether the user holds official platform verification status.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:boolean", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#accountAgeInDays",
   localName: "accountAgeInDays", label: "account age in days",
   comment: "Derived metric: number of days elapsed since account creation at the time of data collection.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:nonNegativeInteger", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#followerFriendRatio",
   localName: "followerFriendRatio", label: "follower-friend ratio",
   comment: "Derived metric: ratio of followerCount to friendCount. High ratios indicate broad influence; very low ratios may signal bot-like behaviour.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#User",
   range: "xsd:decimal", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#hashtagText",
   localName: "hashtagText", label: "hashtag text",
   comment: "The normalised text of the hashtag (without the # prefix, lowercased).",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Hashtag",
   range: "xsd:string", isFunctional: true},

  {uri: "http://cair-nepal.org/ontology/misinformation#mentionHandle",
   localName: "mentionHandle", label: "mention handle",
   comment: "The @handle of the user mentioned in the tweet.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Mention",
   range: "xsd:string", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#urlValue",
   localName: "urlValue", label: "URL value",
   comment: "The expanded (unshortened) URL string embedded in the tweet.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#URL",
   range: "xsd:anyURI", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#urlDomain",
   localName: "urlDomain", label: "URL domain",
   comment: "The registered domain name of the linked URL, used for source credibility analysis.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#URL",
   range: "xsd:string", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#labelValue",
   localName: "labelValue", label: "label value",
   comment: "Numeric encoding of the veracity label: 1 = misinformation, 0 = accurate information.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#InformationLabel",
   range: "xsd:integer", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#annotationConfidence",
   localName: "annotationConfidence", label: "annotation confidence",
   comment: "A real-valued confidence score in [0.0, 1.0] indicating annotator certainty or model probability for the assigned label.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#InformationLabel",
   range: "xsd:decimal", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#annotationTimestamp",
   localName: "annotationTimestamp", label: "annotation timestamp",
   comment: "The date and time at which the annotation was recorded.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#InformationLabel",
   range: "xsd:dateTime", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#interAnnotatorAgreement",
   localName: "interAnnotatorAgreement", label: "inter-annotator agreement",
   comment: "Cohen kappa or Fleiss kappa score reflecting agreement among human annotators for this annotation batch.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#AnnotationEvent",
   range: "xsd:decimal", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#datasetName",
   localName: "datasetName", label: "dataset name",
   comment: "Human-readable name of the research dataset.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Dataset",
   range: "xsd:string", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#datasetSize",
   localName: "datasetSize", label: "dataset size",
   comment: "Total number of tweet instances in the dataset.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Dataset",
   range: "xsd:nonNegativeInteger", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#misinformationRatio",
   localName: "misinformationRatio", label: "misinformation ratio",
   comment: "Proportion of tweets labelled as misinformation within the dataset (class balance indicator).",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Dataset",
   range: "xsd:decimal", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#collectionPeriodStart",
   localName: "collectionPeriodStart", label: "collection period start",
   comment: "Start date of the data collection window.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Dataset",
   range: "xsd:date", isFunctional: false},

  {uri: "http://cair-nepal.org/ontology/misinformation#collectionPeriodEnd",
   localName: "collectionPeriodEnd", label: "collection period end",
   comment: "End date of the data collection window.",
   domainUri: "http://cair-nepal.org/ontology/misinformation#Dataset",
   range: "xsd:date", isFunctional: false}

] AS dp
MERGE (p:Property {uri: dp.uri})
SET p.localName    = dp.localName,
    p.prefix       = "mis",
    p.propertyType = "DatatypeProperty",
    p.label        = dp.label,
    p.comment      = dp.comment,
    p.range        = dp.range,
    p.isFunctional = dp.isFunctional,
    p.isDefinedBy  = "http://cair-nepal.org/ontology/misinformation"
WITH p, dp
MATCH (d:Class {uri: dp.domainUri})
MERGE (p)-[:HAS_DOMAIN]->(d);


// =============================================================================
//  SECTION 11 — NAMED INDIVIDUAL / ENTITY NODES
//  BUG-FIX #3 & #9: isDefinedBy now set on ALL mis: individuals.
//  BUG-FIX #4: SamriddhaPathak now gets INSTANCE_OF foaf:Person AND prov:Agent.
//  BUG-FIX #11: SamriddhaPathak multi-type handled via separate INSTANCE_OF edges.
//  NOTE: Each entity is created with a standalone MERGE…SET statement,
//  followed by a separate MATCH…MERGE for INSTANCE_OF, guaranteeing all
//  Class nodes from Sections 3–4 exist before any MATCH is attempted.
// =============================================================================

// --- 11.1  MisinformationLabel (controlled vocabulary singleton) ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#MisinformationLabel"})
SET e.localName   = "MisinformationLabel",
    e.prefix      = "misind",
    e.label       = "Misinformation",
    e.comment     = "Controlled vocabulary label denoting that the associated tweet has been verified as containing misinformation.",
    e.labelValue  = 1,
    e.notation    = "MIS",
    e.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#MisinformationLabel"})
MATCH (c:Class   {uri: "http://cair-nepal.org/ontology/misinformation#InformationLabel"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.2  AccurateLabel (controlled vocabulary singleton) ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#AccurateLabel"})
SET e.localName   = "AccurateLabel",
    e.prefix      = "misind",
    e.label       = "Accurate Information",
    e.comment     = "Controlled vocabulary label denoting that the associated tweet has been verified as containing accurate information.",
    e.labelValue  = 0,
    e.notation    = "ACC",
    e.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#AccurateLabel"})
MATCH (c:Class   {uri: "http://cair-nepal.org/ontology/misinformation#InformationLabel"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.3  PoliticalDomainInstance ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#PoliticalDomainInstance"})
SET e.localName   = "PoliticalDomainInstance",
    e.prefix      = "misind",
    e.label       = "Political",
    e.notation    = "POL",
    e.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#PoliticalDomainInstance"})
MATCH (c:Class   {uri: "http://cair-nepal.org/ontology/misinformation#PoliticalDomain"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.4  EducationalDomainInstance ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#EducationalDomainInstance"})
SET e.localName   = "EducationalDomainInstance",
    e.prefix      = "misind",
    e.label       = "Educational",
    e.notation    = "EDU",
    e.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#EducationalDomainInstance"})
MATCH (c:Class   {uri: "http://cair-nepal.org/ontology/misinformation#EducationalDomain"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.5  HealthcareDomainInstance ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#HealthcareDomainInstance"})
SET e.localName   = "HealthcareDomainInstance",
    e.prefix      = "misind",
    e.label       = "Healthcare",
    e.notation    = "HLT",
    e.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#HealthcareDomainInstance"})
MATCH (c:Class   {uri: "http://cair-nepal.org/ontology/misinformation#HealthcareDomain"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.6  CAIRDataset_v1 ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#CAIRDataset_v1"})
SET e.localName              = "CAIRDataset_v1",
    e.prefix                 = "misind",
    e.datasetName            = "CAIR-MisDetect Corpus v1.0",
    e.datasetSize            = 15000,
    e.misinformationRatio    = 0.52,
    e.collectionPeriodStart  = "2023-01-01",
    e.collectionPeriodEnd    = "2024-12-31",
    e.comment                = "Multi-domain Twitter/X misinformation dataset covering Political, Educational, and Healthcare domains, collected and annotated by CAIR Nepal.",
    e.isDefinedBy            = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#CAIRDataset_v1"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#Dataset"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.7  annotator_expert_01 ---
// BUG-FIX #3: Added isDefinedBy (was missing — prevented IS_DEFINED_BY sweep).
// BUG-FIX: foaf:name stored as foafName property; INSTANCE_OF HumanAnnotator correct.
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#annotator_expert_01"})
SET e.localName   = "annotator_expert_01",
    e.prefix      = "misind",
    e.foafName    = "Domain Expert Annotator 01",
    e.comment     = "Senior researcher with domain expertise in public health misinformation.",
    e.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#annotator_expert_01"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#HumanAnnotator"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.8  annotationEvent_001 ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#annotationEvent_001"})
SET e.localName                = "annotationEvent_001",
    e.prefix                   = "misind",
    e.interAnnotatorAgreement  = 0.83,
    e.prov_startedAtTime       = "2024-06-01T00:00:00",
    e.prov_endedAtTime         = "2024-06-15T23:59:59",
    e.comment                  = "Annotation batch for Healthcare domain tweets, June 2024. IAA computed using Cohen kappa.",
    e.isDefinedBy              = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#annotationEvent_001"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#AnnotationEvent"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.9  location_kathmandu ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#location_kathmandu"})
SET e.localName             = "location_kathmandu",
    e.prefix                = "misind",
    e.label                 = "Kathmandu, Nepal",
    e.schema_name           = "Kathmandu",
    e.schema_addressCountry = "NP",
    e.isDefinedBy           = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#location_kathmandu"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#Location"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.10  user_samriddha_pathak ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#user_samriddha_pathak"})
SET e.localName           = "user_samriddha_pathak",
    e.prefix              = "misind",
    e.userID              = "987654321",
    e.userName            = "samriddha_pathak",
    e.userDisplayName     = "Samriddha Pathak",
    e.foafName            = "Samriddha Pathak",
    e.userLocation        = "Kathmandu, Nepal",
    e.userDescription     = "AI Researcher | Ontology Engineer | CAIR Nepal",
    e.userCreated         = "2015-03-12T00:00:00",
    e.followerCount       = 1200,
    e.friendCount         = 340,
    e.favouriteCount      = 4500,
    e.tweetCount          = 3200,
    e.isVerified          = false,
    e.accountAgeInDays    = 3383,
    e.followerFriendRatio = 3.53,
    e.isDefinedBy         = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#user_samriddha_pathak"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#UnverifiedUser"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.11  user_retweeter_01 ---
// BUG-FIX #9: Added isDefinedBy (was missing).
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#user_retweeter_01"})
SET e.localName           = "user_retweeter_01",
    e.prefix              = "misind",
    e.userID              = "112233445566",
    e.userName            = "health_advocate_np",
    e.userDisplayName     = "Health Advocate NP",
    e.userLocation        = "Kathmandu, Nepal",
    e.userCreated         = "2018-07-20T00:00:00",
    e.followerCount       = 320,
    e.friendCount         = 210,
    e.favouriteCount      = 980,
    e.tweetCount          = 870,
    e.isVerified          = false,
    e.accountAgeInDays    = 2156,
    e.followerFriendRatio = 1.52,
    e.isDefinedBy         = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#user_retweeter_01"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#UnverifiedUser"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.12  hashtag_vaccines ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#hashtag_vaccines"})
SET e.localName   = "hashtag_vaccines",
    e.prefix      = "misind",
    e.hashtagText = "vaccines",
    e.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#hashtag_vaccines"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#Hashtag"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.13  hashtag_health ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#hashtag_health"})
SET e.localName   = "hashtag_health",
    e.prefix      = "misind",
    e.hashtagText = "health",
    e.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#hashtag_health"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#Hashtag"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.14  label_tweet001 ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#label_tweet001"})
SET e.localName              = "label_tweet001",
    e.prefix                 = "misind",
    e.labelValue             = 1,
    e.annotationConfidence   = 0.95,
    e.annotationTimestamp    = "2024-06-10T14:00:00",
    e.isDefinedBy            = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#label_tweet001"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#InformationLabel"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.15  label_tweet002 ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#label_tweet002"})
SET e.localName              = "label_tweet002",
    e.prefix                 = "misind",
    e.labelValue             = 1,
    e.annotationConfidence   = 0.91,
    e.annotationTimestamp    = "2024-06-10T14:00:00",
    e.isDefinedBy            = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#label_tweet002"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#InformationLabel"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.16  url_refutation_001 ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#url_refutation_001"})
SET e.localName   = "url_refutation_001",
    e.prefix      = "misind",
    e.urlValue    = "https://www.cdc.gov/vaccinesafety/concerns/autism.html",
    e.urlDomain   = "cdc.gov",
    e.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#url_refutation_001"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#URL"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.17  claim_001 ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#claim_001"})
SET e.localName   = "claim_001",
    e.prefix      = "misind",
    e.label       = "Vaccines cause autism claim",
    e.comment     = "A widely circulated and thoroughly debunked claim asserting a causal link between vaccination and autism, originating from a retracted 1998 Lancet paper by Wakefield.",
    e.isDefinedBy = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#claim_001"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#MisinformationClaim"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.18  tweet_001 (OriginalTweet) ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_001"})
SET e.localName          = "tweet_001",
    e.prefix             = "misind",
    e.tweetID            = "1234567890123456789",
    e.tweetText          = "Vaccines cause autism, this has been proven by multiple studies.",
    e.tweetDate          = "2024-06-15T10:30:00",
    e.isRetweet          = false,
    e.isMisinformation   = true,
    e.sourceClient       = "Twitter for Android",
    e.hashtagList        = "#vaccines #health",
    e.retweetCount       = 342,
    e.likeCount          = 89,
    e.replyCount         = 27,
    e.languageCode       = "en",
    e.sensitiveContent   = false,
    e.prov_generatedAtTime = "2024-06-15T10:30:00",
    e.isDefinedBy        = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_001"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#OriginalTweet"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.19  tweet_002 (Retweet) ---
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_002"})
SET e.localName          = "tweet_002",
    e.prefix             = "misind",
    e.tweetID            = "9876543210987654321",
    e.tweetText          = "RT @samriddha_pathak: Vaccines cause autism, this has been proven by multiple studies.",
    e.tweetDate          = "2024-06-15T12:45:00",
    e.isRetweet          = true,
    e.isMisinformation   = true,
    e.sourceClient       = "Twitter for iPhone",
    e.hashtagList        = "#vaccines #health",
    e.retweetCount       = 0,
    e.likeCount          = 5,
    e.replyCount         = 0,
    e.languageCode       = "en",
    e.sensitiveContent   = false,
    e.prov_generatedAtTime = "2024-06-15T12:45:00",
    e.isDefinedBy        = "http://cair-nepal.org/ontology/misinformation";
MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_002"})
MATCH (c:Class  {uri: "http://cair-nepal.org/ontology/misinformation#Retweet"})
MERGE (e)-[:INSTANCE_OF]->(c);

// --- 11.20  SamriddhaPathak (foaf:Person AND prov:Agent — ontology author) ---
// BUG-FIX #4: foaf:Person class now exists (Section 3); INSTANCE_OF edges for
//   both foaf:Person and prov:Agent are now created.
// BUG-FIX #11: Multi-type captured as separate INSTANCE_OF graph edges rather
//   than flat string properties, which cannot carry Neo4j label semantics.
MERGE (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#SamriddhaPathak"})
SET e.localName          = "SamriddhaPathak",
    e.prefix             = "misind",
    e.foafName           = "Samriddha Pathak",
    e.foafMbox           = "mailto:samriddha@cair-nepal.org",
    e.foafOrganization   = "Centre for Artificial Intelligence Research Nepal (CAIR Nepal)",
    e.label              = "Samriddha Pathak",
    e.comment            = "Ontology author and principal researcher at CAIR Nepal. Creator of the MisDetect misinformation ontology.",
    e.isDefinedBy        = "http://cair-nepal.org/ontology/misinformation";

MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#SamriddhaPathak"})
MATCH (c:Class  {uri: "http://xmlns.com/foaf/0.1/Person"})
MERGE (e)-[:INSTANCE_OF]->(c);

MATCH (e:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#SamriddhaPathak"})
MATCH (c:Class  {uri: "http://www.w3.org/ns/prov#Agent"})
MERGE (e)-[:INSTANCE_OF]->(c);


// =============================================================================
//  SECTION 12 — INSTANCE-LEVEL OBJECT PROPERTY EDGES
//  BUG-FIX #13: tweet_002 HAS_HASHTAG edges for vaccines and health added.
//  All edges use MATCH+MERGE to be idempotent and safe.
// =============================================================================

// --- tweet_001 edges ---
MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_001"})
MATCH (u:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#user_samriddha_pathak"})
MERGE (t)-[:HAS_AUTHOR]->(u);

MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_001"})
MATCH (u:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#user_samriddha_pathak"})
MERGE (u)-[:AUTHORED]->(t);

MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_001"})
MATCH (cl:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#claim_001"})
MERGE (t)-[:HAS_CLAIM]->(cl);

MATCH (t:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_001"})
MATCH (cl:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#claim_001"})
MERGE (cl)-[:IS_CLAIM_OF]->(t);

MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_001"})
MATCH (d:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#HealthcareDomainInstance"})
MERGE (t)-[:BELONGS_TO_DOMAIN]->(d);

MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_001"})
MATCH (l:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#label_tweet001"})
MERGE (t)-[:HAS_INFORMATION_LABEL]->(l);

MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_001"})
MATCH (h:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#hashtag_vaccines"})
MERGE (t)-[:HAS_HASHTAG]->(h);

MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_001"})
MATCH (h:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#hashtag_health"})
MERGE (t)-[:HAS_HASHTAG]->(h);

MATCH (t:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_001"})
MATCH (ds:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#CAIRDataset_v1"})
MERGE (t)-[:DERIVED_FROM_DATASET]->(ds);

// --- tweet_002 edges ---
MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_002"})
MATCH (u:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#user_retweeter_01"})
MERGE (t)-[:HAS_AUTHOR]->(u);

MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_002"})
MATCH (u:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#user_retweeter_01"})
MERGE (u)-[:AUTHORED]->(t);

MATCH (t:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_002"})
MATCH (cl:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#claim_001"})
MERGE (t)-[:HAS_CLAIM]->(cl);

MATCH (t:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_002"})
MATCH (cl:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#claim_001"})
MERGE (cl)-[:IS_CLAIM_OF]->(t);

MATCH (t:Entity    {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_002"})
MATCH (orig:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_001"})
MERGE (t)-[:IS_RETWEET_OF]->(orig);

MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_002"})
MATCH (d:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#HealthcareDomainInstance"})
MERGE (t)-[:BELONGS_TO_DOMAIN]->(d);

MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_002"})
MATCH (l:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#label_tweet002"})
MERGE (t)-[:HAS_INFORMATION_LABEL]->(l);

// BUG-FIX #13: tweet_002 hashtagList = "#vaccines #health" but HAS_HASHTAG edges
//   were completely absent in the original script — now added.
MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_002"})
MATCH (h:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#hashtag_vaccines"})
MERGE (t)-[:HAS_HASHTAG]->(h);

MATCH (t:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_002"})
MATCH (h:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#hashtag_health"})
MERGE (t)-[:HAS_HASHTAG]->(h);

MATCH (t:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#tweet_002"})
MATCH (ds:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#CAIRDataset_v1"})
MERGE (t)-[:DERIVED_FROM_DATASET]->(ds);

// --- label_tweet001 edges ---
MATCH (l:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#label_tweet001"})
MATCH (a:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#annotator_expert_01"})
MERGE (l)-[:ANNOTATED_BY]->(a);

MATCH (l:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#label_tweet001"})
MATCH (ev:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#annotationEvent_001"})
MERGE (l)-[:ANNOTATION_METHOD]->(ev);

// --- label_tweet002 edges ---
MATCH (l:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#label_tweet002"})
MATCH (a:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#annotator_expert_01"})
MERGE (l)-[:ANNOTATED_BY]->(a);

MATCH (l:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#label_tweet002"})
MATCH (ev:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#annotationEvent_001"})
MERGE (l)-[:ANNOTATION_METHOD]->(ev);

// --- claim_001 edges ---
MATCH (cl:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#claim_001"})
MATCH (u:Entity  {uri: "http://cair-nepal.org/ontology/misinformation/individuals#url_refutation_001"})
MERGE (cl)-[:REFUTED_BY]->(u);

// --- user edges ---
MATCH (u:Entity   {uri: "http://cair-nepal.org/ontology/misinformation/individuals#user_samriddha_pathak"})
MATCH (loc:Entity {uri: "http://cair-nepal.org/ontology/misinformation/individuals#location_kathmandu"})
MERGE (u)-[:USER_LOCATED_IN]->(loc);

// --- ontology authorship ---
MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (p:Entity   {uri: "http://cair-nepal.org/ontology/misinformation/individuals#SamriddhaPathak"})
MERGE (o)-[:DCTERMS_CREATOR]->(p);


// =============================================================================
//  SECTION 13 — IS_DEFINED_BY SWEEP
//  Connects every mis: Class, Property, and Entity to the Ontology node.
//  These three bulk MATCH statements create IS_DEFINED_BY edges for every
//  node whose isDefinedBy property is set to the ontology URI.
// =============================================================================

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (c:Class)
WHERE c.isDefinedBy = "http://cair-nepal.org/ontology/misinformation"
MERGE (c)-[:IS_DEFINED_BY]->(o);

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (p:Property)
WHERE p.isDefinedBy = "http://cair-nepal.org/ontology/misinformation"
MERGE (p)-[:IS_DEFINED_BY]->(o);

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (e:Entity)
WHERE e.isDefinedBy = "http://cair-nepal.org/ontology/misinformation"
MERGE (e)-[:IS_DEFINED_BY]->(o);


// =============================================================================
//  SECTION 14 — GRAPH CONNECTIVITY FIXES
//  Resolves disconnected islands visible in the relationship graph:
//
//  ISLAND 1 — BlankNode axiom groups
//    BlankNodes have HAS_DISJOINT_MEMBER edges to Classes but no path back to
//    the Ontology node. Fixed by: REFERENCES_ONTOLOGY edge from each BlankNode.
//
//  ISLAND 2 — External vocabulary Class stubs
//    prov:Entity, foaf:Person, nif:String, oa:Annotation, schema:Place, etc.
//    are connected TO mis: Classes via SUBCLASS_OF (inbound) but have no
//    outbound path to the Ontology node. Fixed by: IMPORTS_FROM edges from
//    the Ontology node to each external vocab namespace stub.
//
//  ISLAND 3 — External Property stubs
//    prov:wasAttributedTo and prov:wasDerivedFrom have SUBPROPERTY_OF edges
//    from mis: properties but are otherwise orphaned. Fixed by same mechanism.
// =============================================================================

// --- 14.1  Connect BlankNode axiom groups to the Ontology node ---
MATCH (o:Ontology  {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (b:BlankNode)
WHERE b.rdfType = "owl:AllDisjointClasses"
MERGE (b)-[:REFERENCES_ONTOLOGY]->(o);

// --- 14.2  Connect external vocabulary Class stubs to the Ontology via IMPORTS_FROM ---
//  The Ontology declares it reuses these vocabularies (skos:scopeNote).
//  IMPORTS_FROM makes the external vocab nodes reachable from the Ontology hub.

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (c:Class    {uri: "http://www.w3.org/ns/prov#Entity"})
MERGE (o)-[:IMPORTS_FROM]->(c);

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (c:Class    {uri: "http://www.w3.org/ns/prov#Agent"})
MERGE (o)-[:IMPORTS_FROM]->(c);

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (c:Class    {uri: "http://www.w3.org/ns/prov#Activity"})
MERGE (o)-[:IMPORTS_FROM]->(c);

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (c:Class    {uri: "http://xmlns.com/foaf/0.1/Agent"})
MERGE (o)-[:IMPORTS_FROM]->(c);

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (c:Class    {uri: "http://xmlns.com/foaf/0.1/Person"})
MERGE (o)-[:IMPORTS_FROM]->(c);

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (c:Class    {uri: "http://rdfs.org/sioc/ns#Post"})
MERGE (o)-[:IMPORTS_FROM]->(c);

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (c:Class    {uri: "http://rdfs.org/sioc/ns#UserAccount"})
MERGE (o)-[:IMPORTS_FROM]->(c);

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (c:Class    {uri: "http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#String"})
MERGE (o)-[:IMPORTS_FROM]->(c);

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (c:Class    {uri: "http://www.w3.org/ns/oa#Annotation"})
MERGE (o)-[:IMPORTS_FROM]->(c);

MATCH (o:Ontology {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (c:Class    {uri: "https://schema.org/Place"})
MERGE (o)-[:IMPORTS_FROM]->(c);

// --- 14.3  Connect external Property stubs to the Ontology via IMPORTS_FROM ---

MATCH (o:Ontology  {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (p:Property  {uri: "http://www.w3.org/ns/prov#wasAttributedTo"})
MERGE (o)-[:IMPORTS_FROM]->(p);

MATCH (o:Ontology  {uri: "http://cair-nepal.org/ontology/misinformation"})
MATCH (p:Property  {uri: "http://www.w3.org/ns/prov#wasDerivedFrom"})
MERGE (o)-[:IMPORTS_FROM]->(p);
