## ============================================================
## Bangladeshi Indigenous Languages — Semantic/Phonetic Similarity Pipeline
## Pure R implementation (no Python, no Anaconda, no conda, no reticulate)
##
## Pipeline: Data Preprocessing -> Word2Vec (Skip-gram + CBOW) trained from
## scratch on your own corpus -> Sentence/Language Embeddings (average pooling)
## -> Cosine Similarity Matrices -> Hierarchical Clustering -> Linguistic
## Validation (ARI) -> Geographic Validation -> Visualization
##
## NOTE ON RQ1: Since we are no longer using pretrained SBERT/mBERT, RQ1
## ("which multilingual embedding model is better") is reframed as a
## comparison of Skip-gram vs CBOW training objectives on your own corpus.
## State this explicitly in your paper rather than implying SBERT vs mBERT.
## ============================================================


## ------------------------------------------------------------
## 0. PACKAGE INSTALLATION (run once; safe to re-run — skips installed pkgs)
## ------------------------------------------------------------

required_packages <- c(
  "word2vec",     # pure C++ backend skip-gram / CBOW — no Python needed
  "tidyverse",    # dplyr, stringr, tidyr, ggplot2
  "textclean",    # text normalization helpers
  "proxy",        # cosine similarity / distance
  "pheatmap",     # similarity heatmaps
  "dendextend",   # dendrogram styling
  "mclust",       # adjustedRandIndex for linguistic validation (ARI)
  "geosphere",    # haversine geographic distance
  "Rtsne",        # optional t-SNE visualization
  "ggrepel",      # non-overlapping labels on PCA/t-SNE plots
  "vegan"
)

installed <- rownames(installed.packages())
to_install <- setdiff(required_packages, installed)
if (length(to_install) > 0) {
  install.packages(to_install, dependencies = TRUE)
}

invisible(lapply(required_packages, library, character.only = TRUE))

set.seed(42)  # reproducibility for word2vec training + t-SNE


## ------------------------------------------------------------
## 1. DATASET (already imported in your environment)
## ------------------------------------------------------------
## Expected columns (rename below if your object differs):
##   Bangla | English | Indigenous | Language
## One row = one parallel sentence triple, "Language" = which of the
## 8 indigenous languages the "Indigenous" column is written in.
##
## This assumes a data frame called `raw_df` already exists in your
## environment (from your import). If your imported object has a
## different name, either rename it below or point RAW_DF_NAME to it.

RAW_DF_NAME <- "IDS_Project_dataset"   # <-- change to the name of your imported data frame

if (!exists(RAW_DF_NAME)) {
  stop(paste0("Object '", RAW_DF_NAME,
              "' not found in your environment. Set RAW_DF_NAME to the ",
              "name of your imported dataset object."))
}
raw_df <- get(RAW_DF_NAME)

## If your column names differ, map them here (left = your object's name):
## raw_df <- raw_df %>% rename(Bangla = bn, English = en,
##                              Indigenous = indig_text, Language = lang)

cat("Raw rows loaded:", nrow(raw_df), "\n")
cat("Columns found:", paste(colnames(raw_df), collapse = ", "), "\n")


## ------------------------------------------------------------
## 2. DATA PREPROCESSING
## ------------------------------------------------------------

INDIGENOUS_LANGS <- c("Chakma", "Marma", "Garo", "Kokborok",
                      "Santali", "Khasi", "Mro", "Hajong")

normalize_text <- function(x) {
  x <- as.character(x)
  x <- textclean::replace_non_ascii(x, replacement = "", remove.nonconverted = FALSE)
  x <- str_squish(x)                 # collapse repeated whitespace, trim
  x <- str_replace_all(x, "[\u2018\u2019]", "'")   # curly quotes -> straight
  x <- str_replace_all(x, "[\u201C\u201D]", '"')
  x
}

clean_df <- raw_df %>%
  # remove rows with missing values in any of the 4 core columns
  filter(!is.na(Bangla), !is.na(English), !is.na(Indigenous), !is.na(Language)) %>%
  # trim whitespace before checking emptiness
  mutate(across(c(Bangla, English, Indigenous, Language), ~ str_trim(as.character(.)))) %>%
  # remove empty-string rows
  filter(Bangla != "", English != "", Indigenous != "", Language != "") %>%
  # verify language labels are one of the expected 8
  filter(Language %in% INDIGENOUS_LANGS) %>%
  # normalize text formatting
  mutate(
    Bangla      = normalize_text(Bangla),
    English     = tolower(normalize_text(English)),
    Indigenous  = normalize_text(Indigenous)
  ) %>%
  
  # remove exact duplicate sentence rows
  distinct(Bangla, English, Indigenous, Language, .keep_all = TRUE)

cat("Rows after cleaning:", nrow(clean_df), "\n")
cat("Per-language counts:\n")
print(table(clean_df$Language))

## Bangla/English are parallel translations repeated across indigenous rows.
## De-duplicate them separately (by unique sentence) so we don't waste
## embedding effort re-encoding the same sentence multiple times.
bangla_unique  <- clean_df %>% distinct(Bangla)  %>% pull(Bangla)
english_unique <- clean_df %>% distinct(English) %>% pull(English)

cat("Unique Bangla sentences:", length(bangla_unique), "\n")
cat("Unique English sentences:", length(english_unique), "\n")

write.csv(clean_df, "clean_master_dataset.csv", row.names = FALSE)


## ------------------------------------------------------------
## 3. TOKENIZATION HELPER (shared by all languages)
## ------------------------------------------------------------

tokenize_sentence <- function(x) {
  x <- tolower(x)
  x <- str_replace_all(x, "[^[:alnum:][:space:]']", " ")  # strip punctuation
  x <- str_squish(x)
  str_split(x, " ")[[1]]
}


## ------------------------------------------------------------
## 4. TRAIN WORD2VEC MODELS (Skip-gram + CBOW) FROM SCRATCH
## ------------------------------------------------------------
## RQ1 (reframed): does Skip-gram or CBOW better recover known linguistic
## groupings on this corpus? Both are trained on the FULL combined corpus
## (all 10 "language columns" concatenated as one text stream) so that all
## languages end up in the same embedding space and are directly comparable.

build_training_corpus <- function(df) {
  indigenous_text <- df$Indigenous
  # one Bangla/English sentence contributes once per unique sentence,
  # not once per row, to avoid over-weighting duplicated translations
  c(indigenous_text, bangla_unique, english_unique)
}

training_lines <- build_training_corpus(clean_df)
writeLines(training_lines, "word2vec_training_corpus.txt")

EMBED_DIM <- 100   # vector dimensionality; lower if corpus is small/slow

cat("Training Skip-gram model...\n")
model_skipgram <- word2vec(
  x        = "word2vec_training_corpus.txt",
  type     = "skip-gram",
  dim      = EMBED_DIM,
  window   = 5,
  iter     = 20,
  min_count = 1,          # keep rare words — low-resource languages, small vocab
  threads  = max(1, parallel::detectCores() - 1)
)

cat("Training CBOW model...\n")
model_cbow <- word2vec(
  x        = "word2vec_training_corpus.txt",
  type     = "cbow",
  dim      = EMBED_DIM,
  window   = 5,
  iter     = 20,
  min_count = 1,
  threads  = max(1, parallel::detectCores() - 1)
)

write.word2vec(model_skipgram, "model_skipgram.bin")
write.word2vec(model_cbow, "model_cbow.bin")


## ------------------------------------------------------------
## 5. SENTENCE + LANGUAGE EMBEDDING CONSTRUCTION (average pooling)
## ------------------------------------------------------------

embed_sentence <- function(sentence, w2v_model) {
  tokens <- tokenize_sentence(sentence)
  if (length(tokens) == 0) return(rep(NA_real_, EMBED_DIM))
  vecs <- predict(w2v_model, tokens, type = "embedding")
  vecs <- vecs[complete.cases(vecs), , drop = FALSE]   # drop OOV rows
  if (nrow(vecs) == 0) return(rep(NA_real_, EMBED_DIM))
  colMeans(vecs)   # average pooling across tokens -> one sentence vector
}

embed_language_vector <- function(sentences, w2v_model) {
  mat <- t(sapply(sentences, embed_sentence, w2v_model = w2v_model))
  mat <- mat[complete.cases(mat), , drop = FALSE]
  colMeans(mat)   # average pooling across sentences -> one language vector
}

build_all_language_vectors <- function(w2v_model) {
  lang_vecs <- list()
  
  for (lang in INDIGENOUS_LANGS) {
    sentences <- clean_df %>% filter(Language == lang) %>% pull(Indigenous)
    lang_vecs[[lang]] <- embed_language_vector(sentences, w2v_model)
  }
  lang_vecs[["Bangla"]]  <- embed_language_vector(bangla_unique, w2v_model)
  lang_vecs[["English"]] <- embed_language_vector(english_unique, w2v_model)
  
  do.call(rbind, lang_vecs)   # 10 x EMBED_DIM matrix
}

cat("Building language vectors (Skip-gram)...\n")
lang_matrix_skipgram <- build_all_language_vectors(model_skipgram)

cat("Building language vectors (CBOW)...\n")
lang_matrix_cbow <- build_all_language_vectors(model_cbow)

## Canonical language order used everywhere downstream
LANG_ORDER <- c("Bangla", "English", INDIGENOUS_LANGS)
lang_matrix_skipgram <- lang_matrix_skipgram[LANG_ORDER, ]
lang_matrix_cbow     <- lang_matrix_cbow[LANG_ORDER, ]


## ------------------------------------------------------------
## 6. COSINE SIMILARITY MATRICES (10 x 10)
## ------------------------------------------------------------

cosine_similarity_matrix <- function(mat) {
  sim <- 1 - as.matrix(proxy::dist(mat, method = "cosine"))
  diag(sim) <- 1
  sim
}

sim_matrix_skipgram <- cosine_similarity_matrix(lang_matrix_skipgram)
sim_matrix_cbow     <- cosine_similarity_matrix(lang_matrix_cbow)

write.csv(sim_matrix_skipgram, "similarity_matrix_skipgram.csv")
write.csv(sim_matrix_cbow, "similarity_matrix_cbow.csv")

cat("\n--- Skip-gram similarity matrix ---\n")
print(round(sim_matrix_skipgram, 3))
cat("\n--- CBOW similarity matrix ---\n")
print(round(sim_matrix_cbow, 3))


## ------------------------------------------------------------
## RQ2 / RQ3: most similar indigenous language to Bangla / English
## ------------------------------------------------------------

most_similar_to <- function(sim_matrix, target, candidates) {
  scores <- sim_matrix[target, candidates]
  scores <- sort(scores, decreasing = TRUE)
  scores
}

cat("\nMost similar to Bangla (Skip-gram):\n")
print(most_similar_to(sim_matrix_skipgram, "Bangla", INDIGENOUS_LANGS))

cat("\nMost similar to English (Skip-gram):\n")
print(most_similar_to(sim_matrix_skipgram, "English", INDIGENOUS_LANGS))

cat("\nMost similar to Bangla (CBOW):\n")
print(most_similar_to(sim_matrix_cbow, "Bangla", INDIGENOUS_LANGS))

cat("\nMost similar to English (CBOW):\n")
print(most_similar_to(sim_matrix_cbow, "English", INDIGENOUS_LANGS))


## ------------------------------------------------------------
## 7. HIERARCHICAL CLUSTERING
## ------------------------------------------------------------

K_CLUSTERS <- 3   # matches the 3 known linguistic families

run_clustering <- function(sim_matrix, indig_only = TRUE) {
  langs <- if (indig_only) INDIGENOUS_LANGS else rownames(sim_matrix)
  sub_sim <- sim_matrix[langs, langs]
  dist_obj <- as.dist(1 - sub_sim)   # similarity -> distance
  hc <- hclust(dist_obj, method = "average")
  clusters <- cutree(hc, k = K_CLUSTERS)
  list(hc = hc, clusters = clusters)
}

clust_skipgram <- run_clustering(sim_matrix_skipgram)
clust_cbow     <- run_clustering(sim_matrix_cbow)

cat("\nSkip-gram clusters (k=4):\n"); print(clust_skipgram$clusters)
cat("\nCBOW clusters (k=4):\n"); print(clust_cbow$clusters)



## ------------------------------------------------------------
## 8. LINGUISTIC VALIDATION (Adjusted Rand Index vs known families)
## ------------------------------------------------------------

known_families <- c(
  Chakma   = "Indo-Aryan",
  Hajong   = "Indo-Aryan",
  Marma    = "Sino-Tibetan",
  Garo     = "Sino-Tibetan",
  Kokborok = "Sino-Tibetan",
  Mro      = "Sino-Tibetan",
  Santali  = "Austroasiatic",
  Khasi    = "Austroasiatic"
)
known_families <- known_families[INDIGENOUS_LANGS]  # keep consistent order

ari_skipgram <- mclust::adjustedRandIndex(
  clust_skipgram$clusters[INDIGENOUS_LANGS], known_families
)
ari_cbow <- mclust::adjustedRandIndex(
  clust_cbow$clusters[INDIGENOUS_LANGS], known_families
)

cat("\n=== RQ1 ANSWER: Skip-gram vs CBOW (ARI against known linguistic families) ===\n")
cat("Skip-gram ARI:", round(ari_skipgram, 4), "\n")
cat("CBOW ARI:     ", round(ari_cbow, 4), "\n")
cat("Better model: ", ifelse(ari_skipgram > ari_cbow, "Skip-gram", "CBOW"), "\n")
## ------------------------------------------------------------
## 8b. NON-EMBEDDING BASELINE — Edit Distance (Levenshtein)
## ------------------------------------------------------------
## Justifies using embeddings at all: builds a zero-learned-representation
## baseline from raw string distance on ALIGNED sentence pairs, clusters
## it the same way, and compares ARI against the embedding-based result.

## Build aligned sentence sets: for each pair of languages, use only rows
## where both languages have a translation of the SAME Bangla source
## sentence (so comparisons are on matched content, not random pairs).

build_aligned_edit_distance_matrix <- function(df, langs) {
  n <- length(langs)
  dist_mat <- matrix(NA_real_, n, n, dimnames = list(langs, langs))
  diag(dist_mat) <- 0
  
  for (i in seq_len(n - 1)) {
    for (j in (i + 1):n) {
      lang_i <- langs[i]; lang_j <- langs[j]
      
      df_i <- df %>% filter(Language == lang_i) %>% select(Bangla, Indigenous)
      df_j <- df %>% filter(Language == lang_j) %>% select(Bangla, Indigenous)
      
      ## align on shared Bangla source sentences
      aligned <- inner_join(df_i, df_j, by = "Bangla", suffix = c("_i", "_j"))
      
      if (nrow(aligned) == 0) {
        dist_mat[i, j] <- dist_mat[j, i] <- NA
        next
      }
      
      ## normalized Levenshtein distance per aligned pair, then averaged
      raw_dists <- utils::adist(aligned$Indigenous_i, aligned$Indigenous_j)
      pairwise_dists <- diag(raw_dists)   # element-wise, not full cross matrix
      max_lens <- pmax(nchar(aligned$Indigenous_i), nchar(aligned$Indigenous_j))
      norm_dists <- pairwise_dists / max_lens
      
      mean_dist <- mean(norm_dists, na.rm = TRUE)
      dist_mat[i, j] <- dist_mat[j, i] <- mean_dist
      
      cat(sprintf("  %s vs %s: n_aligned=%d, mean_norm_edit_dist=%.4f\n",
                  lang_i, lang_j, nrow(aligned), mean_dist))
    }
  }
  dist_mat
}

cat("\nBuilding aligned edit-distance baseline matrix...\n")
edit_dist_matrix <- build_aligned_edit_distance_matrix(clean_df, INDIGENOUS_LANGS)

## Cluster the baseline the same way as the embeddings
edit_dist_obj <- as.dist(edit_dist_matrix)
hc_baseline <- hclust(edit_dist_obj, method = "average")
clusters_baseline <- cutree(hc_baseline, k = K_CLUSTERS)

ari_baseline <- mclust::adjustedRandIndex(clusters_baseline[INDIGENOUS_LANGS], known_families)

cat("\n=== Baseline comparison: Edit distance vs Embeddings (ARI vs known families) ===\n")
cat(sprintf("Edit-distance baseline: ARI = %.4f\n", ari_baseline))
cat(sprintf("Skip-gram embedding:    ARI = %.4f\n", ari_skipgram))
cat(sprintf("CBOW embedding:         ARI = %.4f\n", ari_cbow))

write.csv(edit_dist_matrix, "edit_distance_baseline_matrix.csv")
saveRDS(list(ari_baseline = ari_baseline, clusters_baseline = clusters_baseline,
             dist_matrix = edit_dist_matrix),
        "baseline_summary.rds")
cat("\nSaved: edit_distance_baseline_matrix.csv, baseline_summary.rds\n")



build_aligned_edit_distance_matrix_fixed <- function(df, langs) {
  n <- length(langs)
  dist_mat <- matrix(NA_real_, n, n, dimnames = list(langs, langs))
  diag(dist_mat) <- 0
  
  for (i in seq_len(n - 1)) {
    for (j in (i + 1):n) {
      lang_i <- langs[i]; lang_j <- langs[j]
      
      ## deduplicate on Bangla BEFORE joining -> guarantees one-to-one alignment
      df_i <- df %>% filter(Language == lang_i) %>%
        distinct(Bangla, .keep_all = TRUE) %>% select(Bangla, Indigenous)
      df_j <- df %>% filter(Language == lang_j) %>%
        distinct(Bangla, .keep_all = TRUE) %>% select(Bangla, Indigenous)
      
      aligned <- inner_join(df_i, df_j, by = "Bangla", suffix = c("_i", "_j"))
      
      if (nrow(aligned) == 0) {
        dist_mat[i, j] <- dist_mat[j, i] <- NA
        next
      }
      
      raw_dists  <- utils::adist(aligned$Indigenous_i, aligned$Indigenous_j)
      pairwise_dists <- diag(raw_dists)   # now safe: one-to-one after distinct()
      max_lens   <- pmax(nchar(aligned$Indigenous_i), nchar(aligned$Indigenous_j))
      norm_dists <- pairwise_dists / max_lens
      
      mean_dist <- mean(norm_dists, na.rm = TRUE)
      dist_mat[i, j] <- dist_mat[j, i] <- mean_dist
      
      cat(sprintf("  %s vs %s: n_aligned=%d, mean_norm_edit_dist=%.4f\n",
                  lang_i, lang_j, nrow(aligned), mean_dist))
    }
  }
  dist_mat
}

edit_dist_matrix_fixed <- build_aligned_edit_distance_matrix_fixed(clean_df, INDIGENOUS_LANGS)
edit_dist_obj_fixed <- as.dist(edit_dist_matrix_fixed)
hc_baseline_fixed <- hclust(edit_dist_obj_fixed, method = "average")
clusters_baseline_fixed <- cutree(hc_baseline_fixed, k = K_CLUSTERS)
ari_baseline_fixed <- mclust::adjustedRandIndex(clusters_baseline_fixed[INDIGENOUS_LANGS], known_families)

cat(sprintf("\nFixed edit-distance baseline ARI = %.4f (was %.4f before fix)\n",
            ari_baseline_fixed, ari_baseline))
## ------------------------------------------------------------
## 9. GEOGRAPHIC RELATIONSHIP ANALYSIS
## ------------------------------------------------------------
## PLACEHOLDER coordinates — replace with verified district centroids
## before citing correlation results in the paper.

geo_coords <- tibble::tribble(
  ~Language,  ~lat,     ~lon,
  "Chakma",   22.6333,  92.1833,   # Rangamati
  "Marma",    22.2000,  92.2167,   # Bandarban
  "Garo",     24.7500,  90.4000,   # Mymensingh
  "Khasi",    24.9000,  91.8667,   # Sylhet
  "Santali",  25.6333,  88.6333,   # Dinajpur
  "Hajong",   24.7500,  90.4000,   # Mymensingh
  "Mro",      22.2000,  92.2167,   # Bandarban
  "Kokborok", 22.9000,  92.0500    # Chattogram Hill Tracts (approx.)
)

geo_dist_matrix <- geosphere::distm(
  cbind(geo_coords$lon, geo_coords$lat),
  fun = geosphere::distHaversine
) / 1000  # km
rownames(geo_dist_matrix) <- geo_coords$Language
colnames(geo_dist_matrix) <- geo_coords$Language
geo_dist_matrix <- geo_dist_matrix[INDIGENOUS_LANGS, INDIGENOUS_LANGS]


## ------------------------------------------------------------
## 9b. MANTEL TESTS
## ------------------------------------------------------------
## Needs the 'vegan' package — add "vegan" to required_packages at the
## top of the script (Section 0) and re-run that install block once.

library(vegan)

## ============================================================
## (A) SURFACE-OVERLAP DIAGNOSTIC — the most important remaining check
## Tests whether embedding similarity is really tracking phonetic/
## orthographic surface overlap (character trigrams) rather than
## deeper semantic/genealogical structure.
## ============================================================

## --- Build a character-trigram profile per indigenous language ---
build_trigram_profile <- function(sentences) {
  full_text <- paste(sentences, collapse = " ")
  full_text <- tolower(full_text)
  full_text <- str_replace_all(full_text, "[^[:alnum:]]", "")  # strip spaces/punct
  n <- nchar(full_text)
  if (n < 3) return(character(0))
  trigrams <- substring(full_text, 1:(n - 2), 3:n)
  table(trigrams)   # frequency table of character trigrams
}

## Build trigram frequency vectors for all 8 indigenous languages,
## aligned over the UNION of trigrams seen across all languages
trigram_profiles <- lapply(INDIGENOUS_LANGS, function(lang) {
  sentences <- clean_df %>% filter(Language == lang) %>% pull(Indigenous)
  build_trigram_profile(sentences)
})
names(trigram_profiles) <- INDIGENOUS_LANGS

all_trigrams <- unique(unlist(lapply(trigram_profiles, names)))

trigram_matrix <- matrix(0, nrow = length(INDIGENOUS_LANGS), ncol = length(all_trigrams),
                         dimnames = list(INDIGENOUS_LANGS, all_trigrams))
for (lang in INDIGENOUS_LANGS) {
  tp <- trigram_profiles[[lang]]
  trigram_matrix[lang, names(tp)] <- as.numeric(tp)
}

## Normalize each language's row to relative frequency (so corpus-size
## differences across languages, e.g. Chakma's smaller row count,
## don't distort the comparison)
trigram_matrix_norm <- trigram_matrix / rowSums(trigram_matrix)

## Trigram-overlap similarity/distance matrix (cosine, same method as embeddings)
trigram_sim  <- cosine_similarity_matrix(trigram_matrix_norm)
trigram_dist <- as.dist(1 - trigram_sim)

## Embedding distance matrices (indigenous languages only, same order)
embed_dist_skipgram <- as.dist(1 - sim_matrix_skipgram[INDIGENOUS_LANGS, INDIGENOUS_LANGS])
embed_dist_cbow     <- as.dist(1 - sim_matrix_cbow[INDIGENOUS_LANGS, INDIGENOUS_LANGS])

## --- Mantel tests: trigram (surface/phonetic) distance vs embedding distance ---
mantel_surface_skipgram <- vegan::mantel(trigram_dist, embed_dist_skipgram,
                                         method = "spearman", permutations = 9999)
mantel_surface_cbow     <- vegan::mantel(trigram_dist, embed_dist_cbow,
                                         method = "spearman", permutations = 9999)

cat("\n=== RQ7: Surface-overlap (character-trigram) vs embedding distance (Mantel test) ===\n")
cat(sprintf("Skip-gram: r = %.4f, p = %.4f\n",
            mantel_surface_skipgram$statistic, mantel_surface_skipgram$signif))
cat(sprintf("CBOW:      r = %.4f, p = %.4f\n",
            mantel_surface_cbow$statistic, mantel_surface_cbow$signif))
cat("(A high, significant r here means embedding similarity largely tracks\n",
    " phonetic/orthographic surface overlap rather than independent semantic\n",
    " structure — report honestly either way, this directly addresses the\n",
    " confound already flagged in Section 4 of the project discussion.)\n")


## ============================================================
## (B) RQ6 GEOGRAPHIC VALIDATION — replacing plain Spearman with Mantel
## Pairwise distances aren't independent observations (each language
## appears in 7 pairs), so a Mantel test (permutation-based) is the
## statistically correct way to compare two distance matrices — this
## replaces the cor.test() Spearman call from Section 9.
## ============================================================

geo_dist_obj <- as.dist(geo_dist_matrix[INDIGENOUS_LANGS, INDIGENOUS_LANGS])

mantel_geo_skipgram <- vegan::mantel(geo_dist_obj, embed_dist_skipgram,
                                     method = "spearman", permutations = 9999)
mantel_geo_cbow     <- vegan::mantel(geo_dist_obj, embed_dist_cbow,
                                     method = "spearman", permutations = 9999)

cat("\n=== RQ6 (corrected): Geographic distance vs semantic distance (Mantel test) ===\n")
cat(sprintf("Skip-gram: r = %.4f, p = %.4f\n",
            mantel_geo_skipgram$statistic, mantel_geo_skipgram$signif))
cat(sprintf("CBOW:      r = %.4f, p = %.4f\n",
            mantel_geo_cbow$statistic, mantel_geo_cbow$signif))
cat("(This is the statistically correct replacement for the earlier\n",
    " cor.test(..., method='spearman') result — cite THIS number in the paper,\n",
    " not the plain Spearman one.)\n")

## Create the folder first (safe to run even if it already exists)
dir.create("figures", showWarnings = FALSE)

## Then run the png() line again
png("figures/network_graph.png", width = 900, height = 700)
plot(g, layout = layout, vertex.size = 28, vertex.label.color = "black",
     vertex.label.cex = 1.1, edge.color = "gray50",
     main = paste0("Language Similarity Network (Skip-gram, threshold=", THRESHOLD, ")"))
legend("bottomleft", legend = names(family_colors), pt.bg = family_colors,
       pch = 21, pt.cex = 2, bty = "n", title = "Known family")
dev.off()

## ------------------------------------------------------------
## NETWORK GRAPH — Language Similarity as a Graph
## ------------------------------------------------------------
## Needs: igraph package (add to required_packages, install once)
library(igraph)

## Define this here so the block is self-contained
family_colors <- c("Indo-Aryan" = "#E41A1C",
                   "Sino-Tibetan" = "#377EB8",
                   "Austroasiatic" = "#4DAF4A")

sim_indig <- sim_matrix_skipgram[INDIGENOUS_LANGS, INDIGENOUS_LANGS]

THRESHOLD <- 0.95
adj <- sim_indig
adj[adj < THRESHOLD] <- 0
diag(adj) <- 0

g <- graph_from_adjacency_matrix(adj, mode = "undirected",
                                 weighted = TRUE, diag = FALSE)

V(g)$family <- known_families[V(g)$name]
V(g)$color  <- family_colors[V(g)$family]

E(g)$width <- (E(g)$weight - THRESHOLD) * 40 + 1

set.seed(42)
layout <- layout_with_fr(g)

png("figures/network_graph.png", width = 900, height = 700)
plot(g, layout = layout, vertex.size = 28, vertex.label.color = "black",
     vertex.label.cex = 1.1, edge.color = "gray50",
     main = paste0("Language Similarity Network (Skip-gram, threshold=", THRESHOLD, ")"))
legend("bottomleft", legend = names(family_colors), pt.bg = family_colors,
       pch = 21, pt.cex = 2, bty = "n", title = "Known family")
dev.off()

plot(g, layout = layout, vertex.size = 28, vertex.label.color = "black",
     vertex.label.cex = 1.1, edge.color = "gray50",
     main = paste0("Language Similarity Network (Skip-gram, threshold=", THRESHOLD, ")"))
legend("bottomleft", legend = names(family_colors), pt.bg = family_colors,
       pch = 21, pt.cex = 2, bty = "n", title = "Known family")



## --- Save for the paper ---
mantel_summary <- list(
  surface_overlap_skipgram = mantel_surface_skipgram,
  surface_overlap_cbow     = mantel_surface_cbow,
  geographic_skipgram      = mantel_geo_skipgram,
  geographic_cbow          = mantel_geo_cbow
)
saveRDS(mantel_summary, "mantel_test_summary.rds")
cat("\nSaved: mantel_test_summary.rds\n")


## ------------------------------------------------------------
## 10. VISUALIZATION
## ------------------------------------------------------------

dir.create("figures", showWarnings = FALSE)
cat("\nFigures will be saved under:", file.path(getwd(), "figures"), "\n")

## small helper: save a pheatmap object to PNG *and* keep it visible on screen
save_pheatmap_png <- function(ph, filename, width = 7, height = 6) {
  png(filename, width = width, height = height, units = "in", res = 150)
  grid::grid.newpage()
  grid::grid.draw(ph$gtable)
  dev.off()
}

## --- 10a. Similarity Heatmaps ---
## no `filename=` here -> draws in the Plots pane; saved separately below
ph_skipgram <- pheatmap(
  sim_matrix_skipgram,
  main = "Language Similarity — Skip-gram",
  display_numbers = TRUE, number_format = "%.2f"
)
save_pheatmap_png(ph_skipgram, "figures/heatmap_skipgram.png")

ph_cbow <- pheatmap(
  sim_matrix_cbow,
  main = "Language Similarity — CBOW",
  display_numbers = TRUE, number_format = "%.2f"
)
save_pheatmap_png(ph_cbow, "figures/heatmap_cbow.png")

## --- 10b. Dendrograms (colored by known linguistic family) ---
family_colors <- c("Indo-Aryan" = "#E41A1C",
                   "Sino-Tibetan" = "#377EB8",
                   "Austroasiatic" = "#4DAF4A")

plot_dendrogram <- function(hc_obj, title, filename) {
  dend <- as.dendrogram(hc_obj)
  labels_order <- labels(dend)
  fam <- known_families[labels_order]
  dend <- dend %>%
    dendextend::set("labels_col", family_colors[fam]) %>%
    dendextend::set("branches_k_color", k = K_CLUSTERS)
  
  draw_it <- function() {
    plot(dend, main = title, ylab = "1 - cosine similarity")
    legend("topright", legend = names(family_colors), fill = family_colors,
           title = "Known family", bty = "n")
  }
  
  draw_it()                          # 1) draw in the Plots pane
  png(filename, width = 900, height = 600)   # 2) save the same plot to disk
  draw_it()
  dev.off()
}

plot_dendrogram(clust_skipgram$hc, "Dendrogram — Skip-gram", "figures/dendrogram_skipgram.png")
plot_dendrogram(clust_cbow$hc, "Dendrogram — CBOW", "figures/dendrogram_cbow.png")

## --- 10c. PCA Visualization ---
plot_pca <- function(lang_matrix, title, filename) {
  pca <- prcomp(lang_matrix, scale. = TRUE)
  pca_df <- as.data.frame(pca$x[, 1:2])
  pca_df$Language <- rownames(lang_matrix)
  pca_df$Family <- ifelse(pca_df$Language %in% c("Bangla", "English"),
                          "Reference", known_families[pca_df$Language])
  
  p <- ggplot(pca_df, aes(PC1, PC2, color = Family, label = Language)) +
    geom_point(size = 3) +
    ggrepel::geom_text_repel(show.legend = FALSE) +
    labs(title = title,
         x = paste0("PC1 (", round(summary(pca)$importance[2,1]*100,1), "%)"),
         y = paste0("PC2 (", round(summary(pca)$importance[2,2]*100,1), "%)")) +
    theme_minimal()
  
  print(p)                              # 1) show in the Plots pane
  ggsave(filename, p, width = 7, height = 5)  # 2) save to disk
  p
}

pca_skipgram_plot <- plot_pca(lang_matrix_skipgram, "PCA — Skip-gram Language Embeddings",
                              "figures/pca_skipgram.png")
pca_cbow_plot <- plot_pca(lang_matrix_cbow, "PCA — CBOW Language Embeddings",
                          "figures/pca_cbow.png")

## --- 10d. t-SNE Visualization (optional; needs perplexity < n/3) ---
plot_tsne <- function(lang_matrix, title, filename, perplexity = 2) {
  set.seed(42)
  tsne <- Rtsne::Rtsne(lang_matrix, dims = 2, perplexity = perplexity,
                       check_duplicates = FALSE, pca = FALSE)
  tsne_df <- as.data.frame(tsne$Y)
  colnames(tsne_df) <- c("Dim1", "Dim2")
  tsne_df$Language <- rownames(lang_matrix)
  tsne_df$Family <- ifelse(tsne_df$Language %in% c("Bangla", "English"),
                           "Reference", known_families[tsne_df$Language])
  
  p <- ggplot(tsne_df, aes(Dim1, Dim2, color = Family, label = Language)) +
    geom_point(size = 3) +
    ggrepel::geom_text_repel(show.legend = FALSE) +
    labs(title = title) +
    theme_minimal()
  
  print(p)                              # 1) show in the Plots pane
  ggsave(filename, p, width = 7, height = 5)  # 2) save to disk
  p
}

## Only 10 languages total -> perplexity must stay small (<= 3 recommended)
tsne_skipgram_plot <- plot_tsne(lang_matrix_skipgram, "t-SNE — Skip-gram Language Embeddings",
                                "figures/tsne_skipgram.png", perplexity = 2)
tsne_cbow_plot <- plot_tsne(lang_matrix_cbow, "t-SNE — CBOW Language Embeddings",
                            "figures/tsne_cbow.png", perplexity = 2)


## ------------------------------------------------------------
## 11. SAVE FINAL SUMMARY
## ------------------------------------------------------------

summary_report <- list(
  n_rows_clean = nrow(clean_df),
  per_language_counts = table(clean_df$Language),
  ari_skipgram = ari_skipgram,
  ari_cbow = ari_cbow,
  best_model_by_ari = ifelse(ari_skipgram > ari_cbow, "Skip-gram", "CBOW"),
  geo_semantic_cor_skipgram = cor_skipgram$estimate,
  geo_semantic_cor_cbow = cor_cbow$estimate
)

saveRDS(summary_report, "pipeline_summary.rds")
cat("\nPipeline complete. Outputs written: clean_master_dataset.csv, ",
    "similarity_matrix_*.csv, figures/*.png, pipeline_summary.rds\n")


## ------------------------------------------------------------
## 12. MULTI-SEED STABILITY TEST (10 seeds, mean ± SD)
## ------------------------------------------------------------
## Re-trains Skip-gram + CBOW under 10 different seeds, re-clusters,
## and reports how stable the ARI is against random initialization.

stability_seeds <- c(42, 123, 7, 2024, 99, 555, 8, 2025, 17, 300)

run_pipeline_once <- function(seed_val) {
  set.seed(seed_val)
  
  m_sg <- word2vec(
    x = "word2vec_training_corpus.txt", type = "skip-gram",
    dim = EMBED_DIM, window = 5, iter = 20, min_count = 1,
    threads = max(1, parallel::detectCores() - 1)
  )
  m_cb <- word2vec(
    x = "word2vec_training_corpus.txt", type = "cbow",
    dim = EMBED_DIM, window = 5, iter = 20, min_count = 1,
    threads = max(1, parallel::detectCores() - 1)
  )
  
  lm_sg <- build_all_language_vectors(m_sg)[LANG_ORDER, ]
  lm_cb <- build_all_language_vectors(m_cb)[LANG_ORDER, ]
  
  sm_sg <- cosine_similarity_matrix(lm_sg)
  sm_cb <- cosine_similarity_matrix(lm_cb)
  
  cl_sg <- run_clustering(sm_sg)
  cl_cb <- run_clustering(sm_cb)
  
  ari_sg <- mclust::adjustedRandIndex(cl_sg$clusters[INDIGENOUS_LANGS], known_families)
  ari_cb <- mclust::adjustedRandIndex(cl_cb$clusters[INDIGENOUS_LANGS], known_families)
  
  c(skipgram = ari_sg, cbow = ari_cb)
}

cat("\nRunning stability test across", length(stability_seeds), "seeds...\n")
stability_results <- t(sapply(stability_seeds, run_pipeline_once))
rownames(stability_results) <- paste0("seed_", stability_seeds)
print(round(stability_results, 4))

stability_summary <- data.frame(
  model = c("Skip-gram", "CBOW"),
  mean_ARI = c(mean(stability_results[, "skipgram"]), mean(stability_results[, "cbow"])),
  sd_ARI   = c(sd(stability_results[, "skipgram"]),   sd(stability_results[, "cbow"]))
)

cat("\n=== Stability summary (across", length(stability_seeds), "seeds) ===\n")
print(stability_summary)

write.csv(stability_results, "stability_ari_by_seed.csv")
saveRDS(stability_summary, "stability_summary.rds")
cat("\nSaved: stability_ari_by_seed.csv, stability_summary.rds\n")

## ------------------------------------------------------------
## 12b. STABILITY RE-VERIFICATION — threads=1 (deterministic check)
## ------------------------------------------------------------
## Same as Section 12, but threads=1 to isolate TRUE seed sensitivity
## from thread-level non-determinism (async SGD updates).

run_pipeline_once_single_thread <- function(seed_val) {
  set.seed(seed_val)
  
  m_sg <- word2vec(
    x = "word2vec_training_corpus.txt", type = "skip-gram",
    dim = EMBED_DIM, window = 5, iter = 20, min_count = 1,
    threads = 1        # <-- forced single-thread for reproducibility
  )
  m_cb <- word2vec(
    x = "word2vec_training_corpus.txt", type = "cbow",
    dim = EMBED_DIM, window = 5, iter = 20, min_count = 1,
    threads = 1
  )
  
  lm_sg <- build_all_language_vectors(m_sg)[LANG_ORDER, ]
  lm_cb <- build_all_language_vectors(m_cb)[LANG_ORDER, ]
  
  sm_sg <- cosine_similarity_matrix(lm_sg)
  sm_cb <- cosine_similarity_matrix(lm_cb)
  
  cl_sg <- run_clustering(sm_sg)
  cl_cb <- run_clustering(sm_cb)
  
  ari_sg <- mclust::adjustedRandIndex(cl_sg$clusters[INDIGENOUS_LANGS], known_families)
  ari_cb <- mclust::adjustedRandIndex(cl_cb$clusters[INDIGENOUS_LANGS], known_families)
  
  c(skipgram = ari_sg, cbow = ari_cb)
}

cat("\nRe-running stability test with threads=1 (single-threaded, deterministic)...\n")
stability_results_st <- t(sapply(stability_seeds, run_pipeline_once_single_thread))
rownames(stability_results_st) <- paste0("seed_", stability_seeds)
print(round(stability_results_st, 4))

stability_summary_st <- data.frame(
  model = c("Skip-gram", "CBOW"),
  mean_ARI = c(mean(stability_results_st[, "skipgram"]), mean(stability_results_st[, "cbow"])),
  sd_ARI   = c(sd(stability_results_st[, "skipgram"]),   sd(stability_results_st[, "cbow"]))
)
cat("\n=== Stability summary (threads=1) ===\n")
print(stability_summary_st)

write.csv(stability_results_st, "stability_ari_by_seed_threads1.csv")
saveRDS(stability_summary_st, "stability_summary_threads1.rds")






## ============================================================
## ADDITIONAL VALIDATION — run AFTER the main pipeline script
## (uses objects already in your environment: clust_skipgram, clust_cbow,
##  known_families, INDIGENOUS_LANGS, model_skipgram, model_cbow, clean_df,
##  bangla_unique, embed_sentence, tokenize_sentence, EMBED_DIM)
##
## Adds two things reviewers will expect:
##   A) Permutation test — is your ARI better than random clustering?
##   B) Translation-pair retrieval accuracy — a more direct test of
##      whether the embedding recovers known correspondences than a
##      single hard k=3 cluster cut does.
## ============================================================

library(mclust)
library(dplyr)

set.seed(42)

## ------------------------------------------------------------
## A) PERMUTATION TEST FOR ARI SIGNIFICANCE
## ------------------------------------------------------------
## Null distribution: shuffle the known-family labels many times and
## recompute ARI against the SAME clustering. If your observed ARI sits
## far in the right tail, that's evidence the clustering isn't random.

permutation_test_ari <- function(cluster_assignment, true_labels, n_perm = 10000) {
  observed_ari <- mclust::adjustedRandIndex(cluster_assignment, true_labels)
  
  null_aris <- replicate(n_perm, {
    shuffled_labels <- sample(true_labels)
    mclust::adjustedRandIndex(cluster_assignment, shuffled_labels)
  })
  
  p_value <- mean(null_aris >= observed_ari)
  
  list(observed_ari = observed_ari,
       null_mean = mean(null_aris),
       null_sd = sd(null_aris),
       p_value = p_value)
}

perm_skipgram <- permutation_test_ari(
  clust_skipgram$clusters[INDIGENOUS_LANGS], known_families
)
perm_cbow <- permutation_test_ari(
  clust_cbow$clusters[INDIGENOUS_LANGS], known_families
)

cat("=== Permutation test: is clustering better than chance? ===\n")
cat(sprintf("Skip-gram: ARI = %.4f, null mean = %.4f, p = %.4f\n",
            perm_skipgram$observed_ari, perm_skipgram$null_mean, perm_skipgram$p_value))
cat(sprintf("CBOW:      ARI = %.4f, null mean = %.4f, p = %.4f\n",
            perm_cbow$observed_ari, perm_cbow$null_mean, perm_cbow$p_value))
cat("(with only 8 languages / 3 families, don't expect p < 0.05 —",
    "report the effect size and null distribution honestly either way)\n\n")


## ------------------------------------------------------------
## B) TRANSLATION-PAIR RETRIEVAL ACCURACY
## ------------------------------------------------------------
## For each unique Bangla sentence, embed it and check whether its TRUE
## indigenous-language translation is closer to it (in cosine similarity)
## than a set of randomly sampled indigenous sentences. This tests the
## embedding directly at the sentence level rather than via a single
## hard cluster assignment.

retrieval_accuracy <- function(w2v_model, df, bangla_sample_n = 200, n_distractors = 20) {
  # sample unique Bangla sentences that have at least one indigenous pair
  bangla_unique_df <- df %>% distinct(Bangla, .keep_all = TRUE)
  sample_size <- min(bangla_sample_n, nrow(bangla_unique_df))
  bangla_pairs <- bangla_unique_df %>% slice_sample(n = sample_size)
  
  all_indigenous <- df$Indigenous
  
  hits <- 0
  total <- 0
  
  for (i in seq_len(nrow(bangla_pairs))) {
    bangla_sent <- bangla_pairs$Bangla[i]
    true_indig  <- bangla_pairs$Indigenous[i]
    
    bangla_vec <- embed_sentence(bangla_sent, w2v_model)
    if (any(is.na(bangla_vec))) next
    
    distractors <- sample(setdiff(all_indigenous, true_indig), n_distractors)
    candidates  <- c(true_indig, distractors)
    
    cand_vecs <- t(sapply(candidates, embed_sentence, w2v_model = w2v_model))
    valid_rows <- complete.cases(cand_vecs)
    if (!valid_rows[1]) next   # true translation itself was unembeddable
    
    cand_vecs <- cand_vecs[valid_rows, , drop = FALSE]
    candidates <- candidates[valid_rows]
    
    sims <- sapply(seq_len(nrow(cand_vecs)), function(j) {
      sum(bangla_vec * cand_vecs[j, ]) /
        (sqrt(sum(bangla_vec^2)) * sqrt(sum(cand_vecs[j, ]^2)))
    })
    
    best_match <- candidates[which.max(sims)]
    if (best_match == true_indig) hits <- hits + 1
    total <- total + 1
  }
  
  list(accuracy = hits / total, n_evaluated = total,
       chance_level = 1 / (n_distractors + 1))
}

cat("Running retrieval accuracy (Skip-gram)...\n")
retr_skipgram <- retrieval_accuracy(model_skipgram, clean_df)
cat("Running retrieval accuracy (CBOW)...\n")
retr_cbow <- retrieval_accuracy(model_cbow, clean_df)

cat("\n=== Translation-pair retrieval accuracy (top-1 out of 21 candidates) ===\n")
cat(sprintf("Skip-gram: %.1f%% (n=%d, chance level = %.1f%%)\n",
            retr_skipgram$accuracy * 100, retr_skipgram$n_evaluated,
            retr_skipgram$chance_level * 100))
cat(sprintf("CBOW:      %.1f%% (n=%d, chance level = %.1f%%)\n",
            retr_cbow$accuracy * 100, retr_cbow$n_evaluated,
            retr_cbow$chance_level * 100))
cat("(well above chance level = the embedding is picking up SOMETHING",
    "systematic linking a Bangla sentence to its own translation;",
    "at/near chance = embeddings aren't capturing translation correspondence)\n")


## ------------------------------------------------------------
## K-SWEEP: ARI across k=2 to k=6 (to justify k=3 empirically)
## ------------------------------------------------------------
k_values <- 2:6
k_sweep_results <- data.frame(k = k_values, ARI_skipgram = NA, ARI_cbow = NA)

for (i in seq_along(k_values)) {
  k <- k_values[i]
  cl_sg <- cutree(clust_skipgram$hc, k = k)
  cl_cb <- cutree(clust_cbow$hc, k = k)
  
  k_sweep_results$ARI_skipgram[i] <- mclust::adjustedRandIndex(cl_sg[INDIGENOUS_LANGS], known_families)
  k_sweep_results$ARI_cbow[i]     <- mclust::adjustedRandIndex(cl_cb[INDIGENOUS_LANGS], known_families)
}

print(k_sweep_results)
write.csv(k_sweep_results, "k_sweep_results.csv", row.names = FALSE)









## ------------------------------------------------------------
## Save results for the paper
## ------------------------------------------------------------
validation_summary <- list(
  permutation_skipgram = perm_skipgram,
  permutation_cbow = perm_cbow,
  retrieval_skipgram = retr_skipgram,
  retrieval_cbow = retr_cbow
)
saveRDS(validation_summary, "additional_validation_summary.rds")
cat("\nSaved: additional_validation_summary.rds\n")