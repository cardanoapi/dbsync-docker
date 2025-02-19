#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <jansson.h>

// Update JSON keys in the destination JSON file with keys from the source JSON file
// This code is chatgpt generated.
void update_json_keys(const char *source_file, const char *dest_file, const char *output_file) {
    // Load source JSON file
    FILE *source_fp = fopen(source_file, "r");
    if (!source_fp) {
        perror("Error opening source file");
        exit(EXIT_FAILURE);
    }

    fseek(source_fp, 0, SEEK_END);
    long source_size = ftell(source_fp);
    fseek(source_fp, 0, SEEK_SET);
    
    char *source_content = (char *)malloc(source_size + 1);
    if (!source_content) {
        perror("Error allocating memory for source content");
        exit(EXIT_FAILURE);
    }

    fread(source_content, 1, source_size, source_fp);
    source_content[source_size] = '\0';  // Null-terminate the string
    fclose(source_fp);

    json_error_t error;
    json_t *source_json = json_loads(source_content, 0, &error);
    if (!source_json) {
        fprintf(stderr, "Error parsing source JSON: %s\n", error.text);
        exit(EXIT_FAILURE);
    }

    free(source_content);  // No longer needed after parsing

    // Load destination JSON file
    FILE *dest_fp = fopen(dest_file, "r");
    if (!dest_fp) {
        perror("Error opening destination file");
        exit(EXIT_FAILURE);
    }

    fseek(dest_fp, 0, SEEK_END);
    long dest_size = ftell(dest_fp);
    fseek(dest_fp, 0, SEEK_SET);
    
    char *dest_content = (char *)malloc(dest_size + 1);
    if (!dest_content) {
        perror("Error allocating memory for destination content");
        exit(EXIT_FAILURE);
    }

    fread(dest_content, 1, dest_size, dest_fp);
    dest_content[dest_size] = '\0';  // Null-terminate the string
    fclose(dest_fp);

    json_t *dest_json = json_loads(dest_content, 0, &error);
    if (!dest_json) {
        fprintf(stderr, "Error parsing destination JSON: %s\n", error.text);
        exit(EXIT_FAILURE);
    }

    free(dest_content);  // No longer needed after parsing

    // Update destination JSON with source JSON keys and values
    const char *key;
    json_t *value;
    json_object_foreach(source_json, key, value) {
        json_object_set(dest_json, key, value);  // Replace or insert keys
    }

    // Write updated JSON to output file
    FILE *output_fp = fopen(output_file, "w");
    if (!output_fp) {
        perror("Error opening output file");
        exit(EXIT_FAILURE);
    }

    if (json_dumpf(dest_json, output_fp, JSON_INDENT(4)) < 0) {
        fprintf(stderr, "Error writing to output JSON file\n");
        exit(EXIT_FAILURE);
    }

    fclose(output_fp);
    json_decref(source_json);
    json_decref(dest_json);

    printf("Updated JSON saved to %s\n", output_file);
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <source_json> <destination_json> <output_json>\n", argv[0]);
        return EXIT_FAILURE;
    }

    update_json_keys(argv[1], argv[2], argv[3]);
    return EXIT_SUCCESS;
}
