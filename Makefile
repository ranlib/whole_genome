#
# ngs_pipeline
#
ngs_pipeline:
	womtool validate --inputs wf_ngs_pipeline.json wf_ngs_pipeline.wdl
	miniwdl check wf_ngs_pipeline.wdl

ngs_pipeline_docu:
	wdl-aid wf_ngs_pipeline.wdl -o wf_ngs_pipeline.md
	womtool graph wf_ngs_pipeline.wdl > wf_ngs_pipeline.dot
	dot -Tpdf -o wf_ngs_pipeline.pdf wf_ngs_pipeline.dot
	dot -Tjpeg -o wf_ngs_pipeline.jpeg wf_ngs_pipeline.dot
	rm wf_ngs_pipeline.dot

run_ngs_pipeline:
	miniwdl run --debug --dir test-ngs_pipeline --cfg miniwdl_production.cfg --input wf_ngs_pipeline.json wf_ngs_pipeline.wdl

