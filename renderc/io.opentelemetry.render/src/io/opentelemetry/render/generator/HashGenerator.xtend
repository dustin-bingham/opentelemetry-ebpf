// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0

package io.opentelemetry.render.generator

import org.eclipse.xtext.generator.IFileSystemAccess2

import io.opentelemetry.render.render.App
import static io.opentelemetry.render.generator.AppGenerator.outputPath
import static io.opentelemetry.render.generator.RenderGenerator.generatedCodeWarning
import static extension io.opentelemetry.render.extensions.AppExtensions.hashName
import static extension io.opentelemetry.render.extensions.AppExtensions.hashSize

class HashGenerator {

  def void doGenerate(App app, IFileSystemAccess2 fsa) {
    val keys = app.spans.flatMap[messages.map[wire_msg.rpc_id]].toList
    val hash = new PerfectHash(keys, false)

    fsa.generateFile(outputPath(app, "hash.c"), generateC(app, hash))
    fsa.generateFile(outputPath(app, "hash.h"), generateH(app, hash))
  }

  private def generateC(App app, PerfectHash hash) {
    '''
    «generatedCodeWarning()»

    #include <platform/platform.h>

    «hash.g_type» «app.hashName»_g_array[] = {
        «hash.g_array.map[toString].join(",")»
    };
    '''
  }

  private def generateH(App app, PerfectHash hash) {
    '''
    «generatedCodeWarning()»
    #pragma once

    #include <platform/platform.h>

    /**
     * «app.hashName»
     *
     * g_type: «hash.g_type»
     * g_size: «hash.g_size»
     * g_shift: «hash.g_shift»
     * hash_shift: «hash.hash_shift»
     * hash_mask: «hash.hash_mask»
     * n_keys: «hash.n_keys»
     * multiplier: «hash.multiplier»
     * hash_seed: «hash.hash_seed»
     */

    extern «hash.g_type» «app.hashName»_g_array[];

    #define «app.hashSize» «hash.hash_mask + 1»

    static inline u32 «app.hashName»(u32 rpc_id) {
      u32 k = (rpc_id ^ «hash.hash_seed») * «hash.multiplier»;
      return ((k >> «hash.hash_shift») + «app.hashName»_g_array[k >> «hash.g_shift»]) & «hash.hash_mask»;
    }
    '''
  }

}
