gtfstidy \
    --recluster-stops \
    --remove-red-agencies \
    --remove-red-routes \
    --remove-red-services \
    --delete-orphans \
    --dist-threshold-stop 200 \
    --red-stops-fuzzy \
    --drop-shapes \
    --fix \
    --remove-fillers \
    --ensure-stop-parents \
    --stable-stop-ids-parents \
    --explicit-calendar \
    gtfs-nl.zip \
    -o gtfs_netherland_clean.zip
> tidy.log
