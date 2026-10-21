# Exploratory Indigenous Language Similarity Analysis in Bangladesh

### A Word2Vec-Based Study of Language Similarity and Potential Family Recovery

**Author:** Sourovi Akter

## Overview

This project explores potential similarity patterns among eight Indigenous languages of Bangladesh using Word2Vec embeddings, cosine similarity, hierarchical clustering, and a lexical edit-distance baseline. Bangla and English are included as reference languages.

The analysis is exploratory. Computational similarity alone cannot establish linguistic ancestry or definitively classify languages into language families.

## Languages

- **Indigenous languages:** Chakma, Marma, Garo, Kokborok, Santali, Khasi, Mro, and Hajong
- **Reference languages:** Bangla and English

## Dataset

The dataset was collected through web scraping and organized into sentence-level records.

| Dataset statistic | Count |
|---|---:|
| Raw records | 5,906 |
| Records after cleaning | 5,842 |
| Unique Bangla entries | 786 |
| Unique English entries | 810 |

| Indigenous language | Records |
|---|---:|
| Chakma | 543 |
| Garo | 736 |
| Hajong | 775 |
| Khasi | 765 |
| Kokborok | 759 |
| Marma | 800 |
| Mro | 697 |
| Santali | 767 |

The raw dataset is **not included** in this public repository. Before redistributing scraped data, users should check the source websites' terms and applicable permissions.

## Methodology

1. Collect and organize multilingual text.
2. Clean and normalize text and remove duplicates.
3. Train Word2Vec models using **Skip-gram** and **CBOW**.
4. Aggregate word embeddings into language-level representations.
5. Calculate pairwise cosine similarities.
6. Apply hierarchical clustering using average linkage, with three clusters in the main comparison.
7. Compare embedding-based patterns with a lexical edit-distance baseline.
8. Evaluate clustering agreement and compare similarity matrices using Mantel tests.

### Main Word2Vec settings

| Parameter | Value |
|---|---:|
| Vector dimension | 100 |
| Context window | 5 |
| Training iterations | 20 |
| Minimum word count | 1 |
| Random seed | 42 |

Language-level vectors are formed by aggregating word embeddings. Results depend on corpus composition, text preprocessing, and how the embeddings are trained.

## Results

### Clustering and baseline comparison

| Method | Reported ARI | Interpretation |
|---|---:|---|
| Skip-gram | 0.6067 in the reported main run | Variable across logged training conditions |
| CBOW | 0.6067 in the reported main run | Stable across logged conditions |
| Corrected lexical edit-distance baseline | 0.3000 | Baseline comparison |

The Adjusted Rand Index (ARI) measures agreement between a clustering and a reference partition. Its interpretation depends on the reference labels used. The exact reference-label mapping should be checked in the analysis script before interpreting ARI as evidence of language-family recovery.

### Reproducibility across training settings

The reproducibility analysis pooled **39 logged observations per model** across the evaluated conditions.

| Training setting | Skip-gram (Mean ± SD) | CBOW (Mean ± SD) |
|---|---:|---:|
| Multi-thread | 0.57 ± 0.12 | 0.607 ± 0.000 |
| Single-thread, Run 1 | 0.27 ± 0.12 | 0.607 ± 0.000 |
| Single-thread, Run 2 | 0.24 ± 0.00 | 0.607 ± 0.000 |

Across the logged observations, Skip-gram showed greater variability, while CBOW remained consistent under the evaluated conditions. The three setting rows above are setting-specific summaries; they are not the full summary of all 39 observations. The observed stability does not establish that CBOW is universally better or linguistically more valid.

### Selected similarity findings

| Analysis | Reported finding |
|---|---|
| Skip-gram: closest reported Indigenous-language pair | Garo–Mro (0.981) |
| CBOW: closest reported Indigenous-language pair | Marma–Khasi (0.970) |
| Skip-gram: most similar to Bangla | Marma (0.3108) |
| Skip-gram: most similar to English | Chakma (0.3723) |

These scores are specific to the dataset and modelling pipeline. High similarity does not, by itself, demonstrate shared ancestry.

### Surface-similarity matrix comparison

Mantel tests compared the embedding-derived similarity matrices with a surface-similarity matrix.

| Embedding model | Mantel correlation (r) | Reported p-value |
|---|---:|---:|
| Skip-gram | 0.8407 | 0.0001 |
| CBOW | 0.8188 | 0.0004 |

The correlation is strong in the reported analysis. However, the exact construction of the surface-similarity matrix should be verified in the code and documented, including its input text and formula. If it is based on orthographic or character-level overlap, the correlation may partly reflect surface-form similarities also present in the embedding input; it should not be interpreted as independent evidence of semantic or genealogical relationships.

Geographical comparisons are **pending verification** because the coordinates used in the current analysis were marked as placeholders. They are not presented as final findings.

## Visualizations

The following image links assume the image files are stored in the `figures/` directory. If the files are in the repository root instead, update the paths to match their actual locations.

### Skip-gram similarity heatmap

![Skip-gram Similarity Heatmap](figures/heatmap_skipgram.png)

### CBOW similarity heatmap

![CBOW Similarity Heatmap](figures/heatmap_cbow.png)

### Skip-gram dendrogram

![Skip-gram Dendrogram](figures/dendrogram_skipgram.png)

### CBOW dendrogram

![CBOW Dendrogram](figures/dendrogram_cbow.png)

## Repository Structure

```text
indigenous-language-similarity-family-recovery-bangladesh/
├── README.md
├── ids_project.R
├── results/
│   ├── similarity_matrix_skipgram.csv
│   ├── similarity_matrix_cbow.csv
│   └── edit_distance_baseline_matrix.csv
└── figures/
    ├── heatmap_skipgram.png
    ├── heatmap_cbow.png
    ├── dendrogram_skipgram.png
    └── dendrogram_cbow.png
```

This is the intended structure. Keep only filenames that actually exist in the repository, and make sure the figure paths above match the uploaded files.

## Limitations

- **Small and uneven corpora:** Each Indigenous language has a limited number of records, and corpus sizes differ across languages. With `min_count = 1`, rare words may have poorly estimated embeddings.
- **Text preprocessing:** Unicode handling, transcription conventions, duplicates, and orthographic differences can affect similarity. Preprocessing must preserve the scripts used by the included languages.
- **Cross-language comparability:** Training in a shared space does not automatically make all cross-language vectors semantically aligned. Shared scripts, transliteration, paired Bangla/English reference text, and overlapping surface forms may inflate some similarities.
- **Language-level aggregation:** Averaging word vectors can hide variation within a language and depends on which words are included and how they are weighted.
- **Genealogical claims:** Similarity and clustering are exploratory signals, not proof of language-family membership.
- **Geographical analysis:** Geographic results should not be interpreted until the coordinates are verified.
- **Reproducibility:** The raw dataset is not public, so the repository alone is insufficient to reproduce every reported numerical result.

## Future Work

- Validate findings with linguistic experts and trusted linguistic classifications.
- Improve Unicode-aware preprocessing and verify text normalization.
- Compare against character-level and multilingual embedding baselines.
- Test clustering stability across seeds and cluster counts.
- Increase and balance the corpus where reliable data are available.
- Verify geographic metadata before conducting geographic comparisons.
- Evaluate results on independently collected data.

## Reproducibility

The main analysis script is `ids_project.R`. To rerun the analysis, prepare the input dataset locally and update the script's input path as needed. The raw dataset is not included in this repository, so results cannot be reproduced from the public repository alone.

## Citation

If you use or refer to this project, cite it as:

> Akter, Sourovi. *Exploratory Indigenous Language Similarity Analysis in Bangladesh: A Word2Vec-Based Study of Language Similarity and Potential Family Recovery.* GitHub repository.

## Author

**Sourovi Akter**

## Data and Usage Notice

This repository shares project code, selected results, and visualizations for educational and research purposes. The raw scraped dataset is not publicly distributed here. Check source terms and permissions before collecting, reusing, or redistributing scraped material.

---

*This project is an exploratory computational analysis intended to support further investigation of linguistic similarity and language documentation.*
