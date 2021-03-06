__constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST;

float getPixelAsFloat(__read_only image2d_t image, int2 pos) {
    float value;
    int dataType = get_image_channel_data_type(image);
    if(dataType == CLK_FLOAT) {
        value = read_imagef(image, sampler, pos).x;
    } else if(dataType == CLK_UNSIGNED_INT8 || dataType == CLK_UNSIGNED_INT16) {
        value = read_imageui(image, sampler, pos).x;
    } else {
        value = read_imagei(image, sampler, pos).x;
    }
    return value;
}

__kernel void WMAiteration(
        __read_only image2d_t input,
        __read_only image2d_t memoryIn,
        __read_only image2d_t last,
        __write_only image2d_t output,
        __write_only image2d_t memoryOut,
        __private int currentFrameCount,
        __private int frameCount
    ) {
    const int2 pos = {get_global_id(0), get_global_id(1)};

    float newValue = getPixelAsFloat(input, pos);
    float2 oldMemory = read_imagef(memoryIn, sampler, pos).xy;
    float newTotal = oldMemory.x + newValue - getPixelAsFloat(last, pos);
    if(frameCount >= currentFrameCount) {
        newTotal = oldMemory.x + newValue;
    }

    float newNumerator = oldMemory.y + frameCount*newValue - oldMemory.x;

    write_imagef(memoryOut, pos, (float4)(newTotal, newNumerator, 0, 0));
    write_imagef(output, pos, newNumerator / (currentFrameCount*(currentFrameCount + 1.0f)/2.0f));
}
