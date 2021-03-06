#' @importFrom data.table fread setDF
#' @importFrom fgsea fgsea
#' @importFrom clusterProfiler enricher
NULL

#' Read a GMT file
#'
#' @param fname GMT file name.
#'
#' @return A list containing genes and description of each pathway
#' @examples
#' # Read example gmt file
#' gmt_fname <- system.file("extdata", "pathways.gmt", package = "CEMiTool")
#' gmt_in <- read_gmt(gmt_fname)
#'
#' @export

read_gmt <- function(fname){
    res <- list(genes=list(), desc=list())
    gmt <- file(fname)
    gmt_lines <- readLines(gmt)
    close(gmt)
    gmt_list <- lapply(gmt_lines, function(x) unlist(strsplit(x, split="\t")))
    gmt_names <- sapply(gmt_list, '[', 1)
    gmt_desc <- lapply(gmt_list, '[', 2)
    gmt_genes <- lapply(gmt_list, function(x){x[3:length(x)]})
    names(gmt_desc) <- names(gmt_genes) <- gmt_names
    res <- do.call(rbind, lapply(names(gmt_genes),
                function(n) cbind.data.frame(term=n, gene=gmt_genes[[n]], stringsAsFactors=FALSE)))
    res$term <- as.factor(res$term)
    return(res)
}

# Performs Over Representation Analysis for a list of genes and a GMT
#
# @keywords internal
#
# @param topgenes a vector of genes
# @param gmt.list a gmt from prepare.gmt function
# @param allgenes a vector containing all genes to be considered as universe
#
# @return a data.frame containing the results
#
#
ora <- function(mod_name, gmt_list, allgenes, mods){
    if(missing(allgenes)) {
        message("Using all genes in GMT file as universe.")
        allgenes <- unique(gmt_list[, "gene"])
    }
    topgenes <- mods[[mod_name]]
    enriched <- clusterProfiler::enricher(gene = topgenes,
                                          pvalueCutoff = 1,
                                          qvalueCutoff = 1,
                                          universe = allgenes,
                                          TERM2GENE = gmt_list)
                                         # TERM2NAME = gmt_list[['term2name']])
    if (!is.null(enriched) && !is.logical(enriched)) {
        result <- enriched@result
    } else {
        if(mod_name != "Not.Correlated"){
            warning("Enrichment for module ", mod_name, " is NULL")
        }
        result <- data.frame(Module=character(), ID=character(),
                             Description=character(),
                             GeneRatio=numeric(), BgRatio=numeric(),
                             pvalue=numeric(), p.adjust=numeric(),
                             qvalue=numeric(), geneID=character(),
                             Count=numeric(), stringsAsFactors=FALSE)
    }
    return(result)
}


#' Module Overrepresentation Analysis
#'
#' Performs overrepresentation analysis for each co-expression module found.
#'
#' @param cem Object of class \code{CEMiTool}.
#' @param gmt Object of class \code{data.frame} with 2 columns, one with
#' pathways and one with genes
#' @param verbose logical. Report analysis steps.
#' @param ... Optional parameters.
#'
#' @return Object of class \code{CEMiTool}
#'
#' @seealso \code{\link{ora_data}}
#'
#' @examples
#' # Get example CEMiTool object
#' data(cem)
#' # Read gmt file
#' gmt <- read_gmt(system.file('extdata', 'pathways.gmt',
#'                    package='CEMiTool'))
#' # Run module overrepresentation analysis
#' cem <- mod_ora(cem, gmt)
#' # Check results
#' head(ora_data(cem))
#'
#' @rdname mod_ora
#' @export
setGeneric('mod_ora', function(cem, ...) {
    standardGeneric('mod_ora')
})

#' @rdname mod_ora
setMethod('mod_ora', signature(cem='CEMiTool'),
    function(cem, gmt, verbose=FALSE) {
        #cem <- get_args(cem, vars=mget(ls()))
        if(!"gene" %in% names(gmt) | !"term" %in% names(gmt)){
            stop("The gmt object must contain two columns named 'term' and 'gene'")
        }
        if (verbose) {
            message('Running ORA')
            message("Using all genes in GMT file as universe.")
        }
        allgenes <- unique(gmt[, "gene"])
        if(is.null(module_genes(cem))){
              warning("No modules in CEMiTool object! Did you run find_modules()?")
              return(cem)
        }
        mods <- split(cem@module[, "genes"], cem@module[, "modules"])
        res_list <- lapply(names(mods), ora, gmt, allgenes, mods)
        if (all(lapply(res_list, nrow) == 0)){
            warning("Enrichment is NULL. Either your gmt file is inadequate or your modules really aren't enriched for any of the pathways in the gmt file.")
            return(cem)
        }
        names(res_list) <- names(mods)

        res <- lapply(names(res_list), function(x){
            if(nrow(res_list[[x]]) > 0){
                as.data.frame(cbind(x, res_list[[x]]))
            }
        })
        res <- do.call(rbind, res)
        names(res)[names(res) == "x"] <- "Module"

        rownames(res) <- NULL
        cem@ora <- res
        return(cem)
    }
)

#' Retrieve over representation analysis (ORA) results
#'
#' @param cem Object of class \code{CEMiTool}
#'
#' @details This function returns the results of the \code{mod_ora} function on the
#' \code{CEMiTool} object. The ID column corresponds to pathways in the gmt file for which
#' genes in the modules were enriched. The Count column shows the number of genes in the
#' module that are enriched for each pathway. The GeneRatio column shows the proportion of
#' genes in the module enriched for a given pathway out of all the genes in the module
#' enriched for any given pathway. The BgRatio column shows the proportion of genes in a
#' given pathway out of all the genes in the gmt file. For more details, please refer to
#' the \code{clusterProfiler} package documentation.
#'
#' @return Object of class \code{data.frame} with ORA data
#'
#' @references Guangchuang Yu, Li-Gen Wang, Yanyan Han, Qing-Yu He. clusterProfiler:
#' an R package for comparing biological themes among gene clusters. OMICS:
#' A Journal of Integrative Biology. 2012, 16(5):284-287.
#'
#' @examples
#' # Get example CEMiTool object
#' data(cem)
#' # Read gmt file
#' gmt <- read_gmt(system.file('extdata', 'pathways.gmt',
#'                    package='CEMiTool'))
#' # Run module overrepresentation analysis
#' cem <- mod_ora(cem, gmt)
#' # Check results
#' head(ora_data(cem))
#' @rdname ora_data
#' @export
setGeneric("ora_data", function(cem) {
    standardGeneric("ora_data")
})

#' @rdname ora_data
setMethod("ora_data", signature("CEMiTool"),
    function(cem){
        return(cem@ora)
    })

#' Module Gene Set Enrichment Analysis
#'
#' Perfoms Gene Set Enrichment Analysis (GSEA) for each co-expression module found.
#'
#' @param cem Object of class \code{CEMiTool}.
#' @param gsea_scale If TRUE, transform data using z-score transformation. Default: TRUE
#' @param rank_method Character string indicating how to rank genes. Either "mean"
#' (the default) or "median".
#' @param gsea_min_size Minimum gene set size (Default: 15).
#' @param gsea_max_size Maximum gene set size (Default: 1000).
#' @param verbose logical. Report analysis steps.
#' @param ... Optional parameters.
#'
#' @return GSEA results.
#'
#' @examples
#' # Get example CEMiTool object
#' data(cem)
#' # Look at example annotation file
#' sample_annotation(cem)
#' # Run GSEA on network modules
#' cem <- mod_gsea(cem)
#' # Check results
#' gsea_data(cem)
#'
#' @seealso \code{\link{plot_gsea}}
#'
#' @rdname mod_gsea
#' @export
setGeneric('mod_gsea', function(cem, ...) {
    standardGeneric('mod_gsea')
})

#' @rdname mod_gsea
setMethod('mod_gsea', signature(cem='CEMiTool'),
    function(cem, gsea_scale=TRUE, rank_method="mean",
             gsea_min_size=15, gsea_max_size=1000, verbose=FALSE) {
        if(!tolower(rank_method) %in% c("mean", "median")){
            stop("Invalid rank_method type. Valid values are 'mean' and 'median'")
        }
        if(nrow(expr_data(cem, filter=FALSE, apply_vst=FALSE)) == 0){
            warning("CEMiTool object has no expression file!")
              return(cem)
        }

        if (nrow(cem@sample_annotation)==0) {
            warning('Looks like your sample_annotation slot is empty. Cannot proceed with gene set enrichment analysis.')
            return(cem)
        }

        if(is.null(module_genes(cem))){
            warning("No modules in CEMiTool object! Did you run find_modules()?")
            return(cem)
        }

        #cem <- get_args(cem, vars=mget(ls()))

        if (verbose) {
            message('Running GSEA')
        }

        # creates gene sets from modules
        modules <- unique(cem@module[, 'modules'])
        gene_sets <- lapply(modules, function(mod){
            return(cem@module[cem@module[, 'modules']==mod, 'genes'])
        })
        names(gene_sets) <- modules

        annot <- cem@sample_annotation
        class_col <- cem@class_column
        sample_col <- cem@sample_name_column
        classes <- unique(annot[, class_col])

        # Check if expression samples are all in sample_annotation
        expr_samples <- names(expr_data(cem, filter=FALSE, apply_vst=FALSE))
        annot_samples <- sample_annotation(cem)[, sample_col]
        if(!all(expr_samples %in% annot_samples)){
            stop("Sample annotation file does not contain all samples in expression file. Please input new sample annotation file using function sample_annotation()")
        }
        if(length(expr_samples) < length(annot_samples)){
            warning("Expression file has less samples than annotation file. Cutting annotation file.")
            annot <- annot[annot[,sample_col] %in% expr_samples,]
            annot_samples <- annot[, sample_col]
        }

        # expression to z-score
        if(gsea_scale){
            z_expr <- data.frame(t(scale(t(expr_data(cem, filter=FALSE, apply_vst=FALSE)),
                                     center=TRUE,
                                     scale=TRUE)),
                                     check.names = FALSE,
                                     stringsAsFactors=FALSE)
        }else{
            z_expr <- expr_data(cem, filter=FALSE, apply_vst=FALSE)
        }
        # calculates enrichment for each module for each class in annot

        gsea_list <- lapply(classes, function(class_group){

            if (verbose) {
                message('Calculating modules enrichment analysis for class ',
                        class_group)
            }
            # samples of class == class_group
            class_samples <- annot[annot[, class_col]==class_group, sample_col]

            # genes ranked by rank_method
            genes_ranked <- apply(z_expr[, class_samples, drop=FALSE], 1, tolower(rank_method))
            genes_ranked <- sort(genes_ranked, decreasing=TRUE)

            # BiocParallel setting up
            BiocParallel::register(BiocParallel::SerialParam())

            gsea_results <- fgsea::fgsea(pathways=gene_sets,
                                         stats=genes_ranked,
                                         minSize=gsea_min_size,
                                         maxSize=gsea_max_size,
                                         nperm=10000,
                                         nproc=0)
            data.table::setDF(gsea_results)
            gsea_results[, 'leadingEdge'] <- unlist(lapply(gsea_results[, 'leadingEdge'],
                                                           function(ledges){
                                                               ledges <- paste(ledges, collapse=",")
                                                           }))
            columns <- colnames(gsea_results)
            colnames(gsea_results) <- c(columns[1], paste0(columns[-1], "_", class_group))
            return(gsea_results)
        })
        # merging all classes gsea results into one data.frame
        all_classes_df <- Reduce(function(x,y) {
            merge(x,y, all=TRUE, by='pathway')
        }, gsea_list)

        # separating ES / NES / pval
        patterns <- list('es'='^ES_','nes'='^NES_', 'padj'='^padj_')
        out_gsea <- lapply(patterns, function(pattern) {
            desired_stat <- all_classes_df[, c('pathway',
                                               grep(pattern, colnames(all_classes_df),value=TRUE))]
            colnames(desired_stat) <- gsub(pattern, '', colnames(desired_stat))
            return(desired_stat)
        })

        names(out_gsea) <- names(patterns)
        if(all(unlist(lapply(out_gsea, nrow))) == 0){
            warning("Unable to enrich any module for any given class")
        }
        cem@enrichment <- out_gsea
        return(cem)
    })

#' Retrieve Gene Set Enrichment Analysis (GSEA) results
#'
#' @param cem Object of class \code{CEMiTool}
#'
#' @return Object of class \code{list} with GSEA data
#' @examples
#' # Get example CEMiTool object
#' data(cem)
#' # Look at example annotation file
#' sample_annotation(cem)
#' # Run GSEA on network modules
#' cem <- mod_gsea(cem)
#' # Check results
#' gsea_data(cem)
#' @rdname gsea_data
#' @export
setGeneric("gsea_data", function(cem) {
    standardGeneric("gsea_data")
})

#' @rdname gsea_data
setMethod("gsea_data", signature("CEMiTool"),
    function(cem){
        return(cem@enrichment)
    })
